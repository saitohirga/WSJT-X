#include "MultiSettings.hpp"

#include <stdexcept>

#include <QObject>
#include <QSettings>
#include <QString>
#include <QStringList>
#include <QDir>
#include <QApplication>
#include <QStandardPaths>
#include <QMainWindow>
#include <QMenu>
#include <QAction>
#include <QActionGroup>
#include <QMessageBox>
#include <QDialog>
#include <QLineEdit>
#include <QRegularExpression>
#include <QRegularExpressionValidator>
#include <QFormLayout>
#include <QVBoxLayout>
#include <QDialogButtonBox>
#include <QPushButton>
#include <QComboBox>
#include <QLabel>
#include <QList>
#include <QMetaObject>

#include "pimpl_impl.hpp"

namespace
{
  char const * default_string = QT_TRANSLATE_NOOP ("MultiSettings", "Default");
  char const * multi_settings_root_group = "MultiSettings";
  char const * multi_settings_current_group_key = "CurrentMultiSettingsConfiguration";

  // calculate a useable and unique settings file path
  QString settings_path ()
  {
    auto config_directory = QStandardPaths::writableLocation (QStandardPaths::ConfigLocation);
    QDir config_path {config_directory}; // will be "." if config_directory is empty
    if (!config_path.mkpath ("."))
      {
        throw std::runtime_error {"Cannot find a usable configuration path \"" + config_path.path ().toStdString () + '"'};
      }
    return config_path.absoluteFilePath (QApplication::applicationName () + ".ini");
  }

  //
  // Dialog to get a valid new configuration name
  //
  class NameDialog final
    : public QDialog
  {
  public:
    explicit NameDialog (QString const& current_name,
                         QStringList const& current_names,
                         QWidget * parent = nullptr)
      : QDialog {parent}
    {
      setWindowTitle (tr ("New Configuration Name"));

      auto form_layout = new QFormLayout ();
      form_layout->addRow (tr ("Old name:"), &old_name_label_);
      old_name_label_.setText (current_name);
      form_layout->addRow (tr ("&New name:"), &name_line_edit_);

      auto main_layout = new QVBoxLayout (this);
      main_layout->addLayout (form_layout);

      auto button_box = new QDialogButtonBox {QDialogButtonBox::Ok | QDialogButtonBox::Cancel};
      button_box->button (QDialogButtonBox::Ok)->setEnabled (false);
      main_layout->addWidget (button_box);

      auto * name_validator = new QRegularExpressionValidator {QRegularExpression {R"([^/\\]+)"}, this};
      name_line_edit_.setValidator (name_validator);

      connect (&name_line_edit_, &QLineEdit::textChanged, [current_names, button_box] (QString const& name) {
          bool valid {name.trimmed () != tr (default_string) && !current_names.contains (name.trimmed ())};
          button_box->button (QDialogButtonBox::Ok)->setEnabled (valid);
        });
      connect (button_box, &QDialogButtonBox::accepted, this, &QDialog::accept);
      connect (button_box, &QDialogButtonBox::rejected, this, &QDialog::reject);
    }

    QString new_name () const
    {
      return name_line_edit_.text ().trimmed ();
    }

  private:
    QLabel old_name_label_;
    QLineEdit name_line_edit_;
  };

  //
  // Dialog to get a valid new existing name
  //
  class ExistingNameDialog final
    : public QDialog
  {
  public:
    explicit ExistingNameDialog (QStringList const& current_names, QWidget * parent = nullptr)
      : QDialog {parent}
    {
      setWindowTitle (tr ("Configuration to Clone From"));

      name_combo_box_.addItems (current_names);

      auto form_layout = new QFormLayout ();
      form_layout->addRow (tr ("&Source Configuration Name:"), &name_combo_box_);

      auto main_layout = new QVBoxLayout (this);
      main_layout->addLayout (form_layout);

      auto button_box = new QDialogButtonBox {QDialogButtonBox::Ok | QDialogButtonBox::Cancel};
      main_layout->addWidget (button_box);

      connect (button_box, &QDialogButtonBox::accepted, this, &QDialog::accept);
      connect (button_box, &QDialogButtonBox::rejected, this, &QDialog::reject);
    }

    QString name () const
    {
      return name_combo_box_.currentText ();
    }

  private:
    QComboBox name_combo_box_;
  };
}

class MultiSettings::impl final
  : public QObject
{
  Q_OBJECT

public:
  explicit impl ();
  bool reposition ();
  void create_menu_actions (QMainWindow * main_window, QMenu * menu);
  bool exit ();

  QSettings settings_;

private:
  using Dictionary = QMap<QString, QVariant>;

  // create a configuration maintenance sub menu
  QMenu * create_sub_menu (QMenu * parent,
                           QString const& menu_title,
                           QActionGroup * = nullptr);

  // extract all settings from the current QSettings group
  Dictionary get_settings () const;

  // leave the current group and move to the multi settings root group
  void switch_to_root_group ();

  // starting from he multi settings root group, switch back to the
  // current group
  void switch_to_group (QString const& group_name);

  // write the settings values from the dictionary to the current group
  void load_from (Dictionary const&);

  // switch to this configuration
  void select_configuration (QMainWindow *);

  // clone this configuration
  void clone_configuration (QMenu *);

  // update this configuration from another
  void clone_into_configuration (QMainWindow *);

  // reset configuration to default values
  void reset_configuration (QMainWindow *);

  // change configuration name
  void rename_configuration (QMainWindow *);

  // remove a configuration
  void delete_configuration (QMainWindow *);

  QString current_;             // current/new configuration or empty for default
  QStringList available_;       // all non-default configurations
                                // including new one
  bool exit_flag_;              // false means loop around with new
                                // configuration
  QActionGroup * configurations_group_;
  QAction * select_action_;
  QAction * clone_action_;
  QAction * clone_into_action_;
  QAction * reset_action_;
  QAction * rename_action_;
  QAction * delete_action_;
  QList<QMetaObject::Connection> action_connections_;
  QMenu * active_sub_menu_;
};

#include "MultiSettings.moc"

MultiSettings::MultiSettings ()
{
}

MultiSettings::~MultiSettings ()
{
}

QSettings * MultiSettings::settings ()
{
  return &m_->settings_;
}

void MultiSettings::create_menu_actions (QMainWindow * main_window, QMenu * menu)
{
  m_->create_menu_actions (main_window, menu);
}

bool MultiSettings::exit ()
{
  return m_->exit ();
}

MultiSettings::impl::impl ()
  : settings_ {settings_path (), QSettings::IniFormat}
  , exit_flag_ {true}
  , configurations_group_ {new QActionGroup {this}}
  , select_action_ {new QAction {tr ("&Switch To"), this}}
  , clone_action_ {new QAction {tr ("&Clone"), this}}
  , clone_into_action_ {new QAction {tr ("Clone &Into ..."), this}}
  , reset_action_ {new QAction {tr ("R&eset"), this}}
  , rename_action_ {new QAction {tr ("&Rename ..."), this}}
  , delete_action_ {new QAction {tr ("&Delete"), this}}
  , active_sub_menu_ {nullptr}
{
  if (!settings_.isWritable ())
    {
      throw std::runtime_error {QString {"Cannot access \"%1\" for writing"}
        .arg (settings_.fileName ()).toStdString ()};
    }
  current_ = settings_.value (multi_settings_current_group_key).toString ();
  reposition ();
}

bool MultiSettings::impl::reposition ()
{
  // save new current and reposition settings
  // assumes settings are positioned at the root
  settings_.setValue (multi_settings_current_group_key, current_);
  settings_.beginGroup (multi_settings_root_group);
  available_ = settings_.childGroups ();
  if (current_.size ())      // new configuration is not the default
    {
      if (!available_.contains (current_))
        {
          // insert new group name as it may not have been created yet
          available_ << current_;
        }
      // switch to the specified configuration
      settings_.beginGroup (current_);
    }
  else
    {
      settings_.endGroup ();  // back to root for default configuration
    }
  bool exit {exit_flag_};
  exit_flag_ = true;          // reset exit flag so normal exit works
  return exit;
}

// populate a pop up menu with the configurations sub-menus for
// maintenance including select, clone, clone from, delete, rename
// and, reset
void MultiSettings::impl::create_menu_actions (QMainWindow * main_window, QMenu * menu)
{
  // add the default configuration sub menu
  QMenu * default_menu = create_sub_menu (menu, tr (default_string), configurations_group_);

  // add all the other configurations
  for (auto const& configuration_name: available_)
    {
      QMenu * configuration_menu = create_sub_menu (menu, configuration_name, configurations_group_);
      if (current_ == configuration_name)
        {
          default_menu = configuration_menu;
        }
    }
  // and set the current configuration
  default_menu->menuAction ()->setChecked (true);

  // hook up configuration actions
  action_connections_ << connect (select_action_, &QAction::triggered, [this, main_window] (bool) {
      select_configuration (main_window);
    });
  action_connections_ << connect (clone_action_, &QAction::triggered, [this, menu] (bool) {
      clone_configuration (menu);
    });
  action_connections_ << connect (clone_into_action_, &QAction::triggered, [this, main_window] (bool) {
      clone_into_configuration (main_window);
    });
  action_connections_ << connect (rename_action_, &QAction::triggered, [this, main_window] (bool) {
      rename_configuration (main_window);
    });
  action_connections_ << connect (reset_action_, &QAction::triggered, [this, main_window] (bool) {
      reset_configuration (main_window);
    });
  action_connections_ << connect (delete_action_, &QAction::triggered, [this, main_window] (bool) {
      delete_configuration (main_window);
    });
}

// call this at the end of the main program loop to determine if the
// main window really wants to quit or to run again with a new configuration
bool MultiSettings::impl::exit ()
{
  for (auto const& connection: action_connections_)
    {
      disconnect (connection);
    }
  action_connections_.clear ();

  if (settings_.group ().size ()) // not default configuration
    {
      // back to the settings root
      settings_.endGroup ();
      settings_.endGroup ();
    }
  return reposition ();
}

QMenu * MultiSettings::impl::create_sub_menu (QMenu * parent_menu,
                                              QString const& menu_title,
                                              QActionGroup * action_group)
{
  QMenu * sub_menu = parent_menu->addMenu (menu_title);
  if (action_group) action_group->addAction (sub_menu->menuAction ());
  sub_menu->menuAction ()->setCheckable (true);
  sub_menu->addAction (select_action_);
  sub_menu->addSeparator ();
  sub_menu->addAction (clone_action_);
  sub_menu->addAction (clone_into_action_);
  sub_menu->addAction (rename_action_);
  sub_menu->addAction (reset_action_);
  sub_menu->addAction (delete_action_);
  connect (sub_menu, &QMenu::aboutToShow, [this, sub_menu] () {
      bool is_default {sub_menu->menuAction ()->text () == tr (default_string)};
      bool is_current {sub_menu->menuAction ()->text () == current_
          || (current_.isEmpty () && is_default)};
      select_action_->setEnabled (!is_current);
      clone_into_action_->setEnabled (!is_current);
      rename_action_->setEnabled (!is_current && !is_default);
      reset_action_->setEnabled (!is_current);
      delete_action_->setEnabled (!is_default && !is_current);
      active_sub_menu_ = sub_menu;
    });
  return sub_menu;
}

auto MultiSettings::impl::get_settings () const -> Dictionary
{
  Dictionary settings;
  for (auto const& key: settings_.allKeys ())
    {
      // filter out multi settings keys
      if (!key.contains (multi_settings_current_group_key)
          && !key.contains (multi_settings_root_group))
        {
          settings[key] = settings_.value (key);
        }
    }
  return settings;
}

void MultiSettings::impl::switch_to_root_group ()
{
  if (current_.size ())
    {
      settings_.endGroup ();
    }
  else
    {
      settings_.beginGroup (multi_settings_root_group);
    }
}

void MultiSettings::impl::switch_to_group (QString const& group_name)
{
  if (group_name.size () && group_name != tr (default_string))
    {
      settings_.beginGroup (group_name);
    }
  else
    {
      settings_.endGroup ();    // back to root for default
    }
}

void MultiSettings::impl::load_from (Dictionary const& dictionary)
{
  for (Dictionary::const_iterator iter = dictionary.constBegin ();
       iter != dictionary.constEnd (); ++iter)
    {
      settings_.setValue (iter.key (), iter.value ());
    }
}

void MultiSettings::impl::select_configuration (QMainWindow * main_window)
{
  if (active_sub_menu_)
    {
      auto const& name = active_sub_menu_->title ();

      if (name != current_)
        {
          current_ = tr (default_string) == name ? QString {} : name;
          exit_flag_ = false;
          main_window->close ();
        }
    }
}

void MultiSettings::impl::clone_configuration (QMenu * menu)
{
  if (active_sub_menu_)
    {
      auto const& name = active_sub_menu_->title ();

      // grab the data to clone
      Dictionary old_settings {get_settings ()};

      switch_to_root_group ();

      // find a new unique name
      QString new_name_root {name + " - Copy"};;
      QString new_name {new_name_root};
      unsigned index {0};
      do
        {
          if (index++) new_name = new_name_root + '(' + QString::number (index) + ')';
        }
      while (settings_.childGroups ().contains (new_name));
      settings_.beginGroup (new_name);

      // Clone the settings
      load_from (old_settings);

      // switch back to current group
      settings_.endGroup ();
      switch_to_group (current_);

      // insert the new configuration sub menu in the parent menu
      create_sub_menu (menu, new_name, configurations_group_);
    }
}

void MultiSettings::impl::clone_into_configuration (QMainWindow * main_window)
{
  if (active_sub_menu_)
    {
      auto const& name = active_sub_menu_->title ();

      switch_to_root_group ();

      // get the source configuration name for the clone
      QStringList sources {settings_.childGroups ()};
      if (name != tr (default_string))
        {
          sources.removeOne (name);
          sources << tr (default_string);
        }
      ExistingNameDialog dialog {sources, main_window};
      if (sources.size () && (1 == sources.size () || QDialog::Accepted == dialog.exec ()))
        {
          QString source_name {1 == sources.size () ? sources.at (0) : dialog.name ()};
          if (QMessageBox::Yes == QMessageBox::question (main_window,
                                                         tr ("Clone Into Configuration"),
                                                         tr ("Confirm overwrite of all values for configuration \"%1\" with values from \"%2\"?")
                                                         .arg (name)
                                                         .arg (source_name)))
            {
              // grab the data to clone
              switch_to_group (source_name);
              Dictionary clone_settings {get_settings ()};

              if (tr (default_string) == source_name)
                {
                  settings_.beginGroup (multi_settings_root_group);
                }
              else
                {
                  settings_.endGroup ();
                }

              // purge target settings
              if (tr (default_string) == name)
                {
                  settings_.endGroup ();
                  // piecemeal reset for default configuration
                  for (auto const& key: settings_.allKeys ())
                    {
                      if (!key.contains (multi_settings_current_group_key)
                          && !key.contains (multi_settings_root_group))
                        {
                          settings_.remove (key);
                        }
                    }
                }
              else
                {
                  settings_.beginGroup (name);
                  settings_.remove (""); // purge entire group
                }

              // load the settings
              load_from (clone_settings);

              if (tr (default_string) == name)
                {
                  settings_.beginGroup (multi_settings_root_group);
                }
              else
                {
                  settings_.endGroup ();
                }
            }
        }

      switch_to_group (current_);
    }
}

void MultiSettings::impl::reset_configuration (QMainWindow * main_window)
{
  if (active_sub_menu_)
    {
      auto const& name = active_sub_menu_->title ();

      if (QMessageBox::Yes != QMessageBox::question (main_window,
                                                     tr ("Reset Configuration"),
                                                     tr ("Confirm reset to default values for configuration \"%1\"?")
                                                     .arg (name)))
        {
          return;
        }

      switch_to_root_group ();

      if (tr (default_string) == name)
        {
          settings_.endGroup ();
          // piecemeal reset for default configuration
          for (auto const& key: settings_.allKeys ())
            {
              if (!key.contains (multi_settings_current_group_key)
                  && !key.contains (multi_settings_root_group))
                {
                  settings_.remove (key);
                }
            }
          settings_.beginGroup (multi_settings_root_group);
        }
      else
        {
          settings_.beginGroup (name);
          settings_.remove (""); // purge entire group
          settings_.endGroup ();
        }
      switch_to_group (current_);
    }
}

void MultiSettings::impl::rename_configuration (QMainWindow * main_window)
{
  if (active_sub_menu_)
    {
      auto const& name = active_sub_menu_->title ();

      switch_to_root_group ();

      // get the new name
      NameDialog dialog {name, settings_.childGroups (), main_window};
      if (QDialog::Accepted == dialog.exec ())
        {
          // switch to the target group and fetch the configuration data
          settings_.beginGroup (name);

          // Clone the settings
          Dictionary target_settings {get_settings ()};
          settings_.endGroup ();
          settings_.beginGroup (dialog.new_name ());
          load_from (target_settings);

          // purge the old configuration data
          settings_.endGroup ();
          settings_.beginGroup (name);
          settings_.remove (""); // purge entire group
          settings_.endGroup ();

          // change the action text in the menu
          active_sub_menu_->setTitle (dialog.new_name ());
        }

      switch_to_group (current_);
    }
}

void MultiSettings::impl::delete_configuration (QMainWindow * main_window)
{
  if (active_sub_menu_)
    {
      auto const& name = active_sub_menu_->title ();

      if (QMessageBox::Yes != QMessageBox::question (main_window,
                                                     tr ("Delete Configuration"),
                                                     tr ("Confirm deletion of configuration \"%1\"?")
                                                     .arg (name)))
        {
          return;
        }

      switch_to_root_group ();

      settings_.beginGroup (name);
      settings_.remove (""); // purge entire group
      settings_.endGroup ();
      switch_to_group (current_);

      active_sub_menu_->deleteLater (), active_sub_menu_ = nullptr;
    }
}
