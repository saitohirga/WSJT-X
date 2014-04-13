#include "TestConfiguration.hpp"

#include <cstdlib>

#include <QApplication>
#include <QSettings>
#include <QMainWindow>
#include <QLabel>
#include <QDir>
#include <QMessageBox>
#include <QLineEdit>
#include <QDebug>
#include <QSortFilterProxyModel>

#include "revision_utils.hpp"
#include "Bands.hpp"
#include "FrequencyList.hpp"
#include "Configuration.hpp"
#include "LiveFrequencyValidator.hpp"

#include "pimpl_impl.hpp"

#include "ui_TestConfiguration.h"

namespace
{
  char const * const title = "Configuration Test v" WSJTX_STRINGIZE (CONFIG_TEST_VERSION_MAJOR) "." WSJTX_STRINGIZE (CONFIG_TEST_VERSION_MINOR) "." WSJTX_STRINGIZE (CONFIG_TEST_VERSION_PATCH) ", " WSJTX_STRINGIZE (SVNVERSION);

  // these undocumented flag values when stored in (Qt::UserRole - 1)
  // of a ComboBox item model index allow the item to be enabled or
  // disabled
  int const combo_box_item_enabled (32 | 1);
  int const combo_box_item_disabled (0);

  auto LCD_error = "-- Error --";
}

class status_bar_frequency final
  : public QLabel
{
public:
  status_bar_frequency (QString const& prefix, QWidget * parent = 0)
    : QLabel {parent}
    , prefix_ {prefix}
  {
  }

  void setText (QString const& text)
  {
    QLabel::setText (prefix_ + " Frequency: " + text);
  }

private:
  QString prefix_;
};

class TestConfiguration::impl final
  : public QMainWindow
{
  Q_OBJECT;

public:
  using Frequency = Radio::Frequency;

  explicit impl (QString const& instance_key, QSettings *, QWidget * parent = nullptr);

  void closeEvent (QCloseEvent *) override;

  Q_SIGNAL void new_frequency (Frequency) const;
  Q_SIGNAL void new_tx_frequency (Frequency = 0, bool rationalise_mode = true) const;

private:
  Q_SLOT void on_configuration_action_triggered ();
  Q_SLOT void on_band_combo_box_activated (int);
  Q_SLOT void on_mode_combo_box_activated (int);
  Q_SLOT void on_PTT_push_button_clicked (bool);
  Q_SLOT void on_split_push_button_clicked (bool);
  Q_SLOT void on_TX_offset_spin_box_valueChanged (int);
  Q_SLOT void on_sync_push_button_clicked (bool);

  Q_SLOT void handle_transceiver_update (Transceiver::TransceiverState);
  Q_SLOT void handle_transceiver_failure (QString);

  void information_message_box (QString const& reason, QString const& detail);
  void read_settings ();
  void write_settings ();
  void load_models ();
  void sync_rig ();
  void band_changed (Frequency);
  void frequency_changed (Frequency);

  Ui::test_configuration_main_window * ui_;
  QSettings * settings_;
  QString callsign_;
  Configuration configuration_dialog_;
  bool updating_models_;	// hold off UI reaction while adjusting models
  bool band_edited_;

  Transceiver::TransceiverState rig_state_;

  Frequency desired_frequency_;

  status_bar_frequency RX_frequency_;
  status_bar_frequency TX_frequency_;
};

#include "TestConfiguration.moc"

TestConfiguration::TestConfiguration (QString const& instance_key, QSettings * settings, QWidget * parent)
  : m_ {instance_key, settings, parent}
{
}

TestConfiguration::~TestConfiguration ()
{
}

TestConfiguration::impl::impl (QString const& instance_key, QSettings * settings, QWidget * parent)
  : QMainWindow {parent}
  , ui_ {new Ui::test_configuration_main_window}
  , settings_ {settings}
  , configuration_dialog_ {instance_key, settings, this}
  , updating_models_ {false}
  , band_edited_ {false}
  , desired_frequency_ {0u}
  , RX_frequency_ {"RX"}
  , TX_frequency_ {"TX"}
{
  ui_->setupUi (this);

  setWindowTitle (program_title (revision ()));

  // mode "Unknown" is display only
  ui_->mode_combo_box->setItemData (ui_->mode_combo_box->findText ("Unknown"), combo_box_item_disabled, Qt::UserRole - 1);

  // setup status bar widgets
  statusBar ()->insertPermanentWidget (0, &TX_frequency_);
  statusBar ()->insertPermanentWidget (0, &RX_frequency_);

  // assign push button ids
  ui_->TX_button_group->setId (ui_->vfo_0_TX_push_button, 0);
  ui_->TX_button_group->setId (ui_->vfo_1_TX_push_button, 1);

  // enable live band combo box entry validation and action
  auto band_validator = new LiveFrequencyValidator {ui_->band_combo_box
                                                    , configuration_dialog_.bands ()
                                                    , configuration_dialog_.frequencies ()
                                                    , this};
  ui_->band_combo_box->setValidator (band_validator);
  connect (band_validator, &LiveFrequencyValidator::valid, this, &TestConfiguration::impl::band_changed);
  connect (ui_->band_combo_box->lineEdit (), &QLineEdit::textEdited, [this] (QString const&) {band_edited_ = true;});

  // hook up band data model
  ui_->band_combo_box->setModel (configuration_dialog_.frequencies ());

  // combo box drop downs are limited to the drop down selector width,
  // this almost random increase improves the situation
  ui_->band_combo_box->view ()->setMinimumWidth (ui_->band_combo_box->view ()->sizeHintForColumn (0) + 10);

  // hook up configuration signals
  connect (&configuration_dialog_, &Configuration::transceiver_update, this, &TestConfiguration::impl::handle_transceiver_update);
  connect (&configuration_dialog_, &Configuration::transceiver_failure, this, &TestConfiguration::impl::handle_transceiver_failure);

  // hook up configuration slots
  connect (this, &TestConfiguration::impl::new_frequency, &configuration_dialog_, &Configuration::transceiver_frequency);
  connect (this, &TestConfiguration::impl::new_tx_frequency, &configuration_dialog_, &Configuration::transceiver_tx_frequency);

  load_models ();

  read_settings ();

  show ();
}

void TestConfiguration::impl::closeEvent (QCloseEvent * e)
{
  write_settings ();

  QMainWindow::closeEvent (e);
}

void TestConfiguration::impl::on_configuration_action_triggered ()
{
  qDebug () << "TestConfiguration::on_configuration_action_triggered";
  if (QDialog::Accepted == configuration_dialog_.exec ())
    {
      qDebug () << "TestConfiguration::on_configuration_action_triggered: Configuration changed";
      qDebug () << "TestConfiguration::on_configuration_action_triggered: rig is" << configuration_dialog_.rig_name ();

      if (configuration_dialog_.restart_audio_input ())
        {
          qDebug () << "Audio Device Changes - Configuration changes require an audio input device to be restarted";
        }
      if (configuration_dialog_.restart_audio_output ())
        {
          qDebug () << "Audio Device Changes - Configuration changes require an audio output device to be restarted";
        }

      load_models ();
    }
  else
    {
      qDebug () << "TestConfiguration::on_configuration_action_triggered: Confiugration changes cancelled";
    }
}

void TestConfiguration::impl::on_band_combo_box_activated (int index)
{
  qDebug () << "TestConfiguration::on_band_combo_box_activated: " << ui_->band_combo_box->currentText ();

  auto model = configuration_dialog_.frequencies ();
  auto value = model->data (model->index (index, 2), Qt::DisplayRole).toString ();

  if (configuration_dialog_.bands ()->data (QModelIndex {}).toString () == value)
    {
      ui_->band_combo_box->lineEdit ()->setStyleSheet ("QLineEdit {color: yellow; background-color : red;}");
    }
  else
    {
      ui_->band_combo_box->lineEdit ()->setStyleSheet ({});
    }

  ui_->band_combo_box->setCurrentText (value);

  auto f = model->data (model->index (index, 0), Qt::UserRole + 1).value<Frequency> ();

  band_edited_ = true;
  band_changed (f);
}

void TestConfiguration::impl::band_changed (Frequency f)
{
  if (band_edited_)
    {
      band_edited_ = false;
      frequency_changed (f);
      sync_rig ();
    }
}

void TestConfiguration::impl::frequency_changed (Frequency f)
{
  desired_frequency_ = f;

  // lookup band
  auto bands_model = configuration_dialog_.bands ();
  ui_->band_combo_box->setCurrentText (bands_model->data (bands_model->find (f)).toString ());
}

void TestConfiguration::impl::on_sync_push_button_clicked (bool /* checked */)
{
  qDebug () << "TestConfiguration::on_sync_push_button_clicked";

  auto model = configuration_dialog_.frequencies ();
  auto model_index = model->index (ui_->band_combo_box->currentIndex (), 0);
  desired_frequency_ = model->data (model_index, Qt::UserRole + 1).value<Frequency> ();

  sync_rig ();
}

void TestConfiguration::impl::on_mode_combo_box_activated (int index)
{
  qDebug () << "TestConfiguration::on_vfo_A_mode_combo_box_activated: " << static_cast<Transceiver::MODE> (index);

  // reset combo box back to current mode and let status update do the actual change
  ui_->mode_combo_box->setCurrentIndex (rig_state_.mode ());

  Q_EMIT configuration_dialog_.transceiver_mode (static_cast<Transceiver::MODE> (index));
}

void TestConfiguration::impl::on_TX_offset_spin_box_valueChanged (int value)
{
  qDebug () << "TestConfiguration::on_TX_offset_spin_box_editingFinished: " << value;

  Q_EMIT new_tx_frequency (rig_state_.frequency () + value);
}

void TestConfiguration::impl::on_PTT_push_button_clicked (bool checked)
{
  qDebug () << "TestConfiguration::on_PTT_push_button_clicked: " << (checked ? "true" : "false");

  // reset button and let status update do the actual checking
  ui_->PTT_push_button->setChecked (rig_state_.ptt ());

  Q_EMIT configuration_dialog_.transceiver_ptt (checked);
}

void TestConfiguration::impl::on_split_push_button_clicked (bool checked)
{
  qDebug () << "TestConfiguration::on_split_push_button_clicked: " << (checked ? "true" : "false");

  // reset button and let status update do the actual checking
  ui_->split_push_button->setChecked (rig_state_.split ());

  if (checked)
    {
      Q_EMIT new_tx_frequency (rig_state_.frequency () + ui_->TX_offset_spin_box->value ());
    }
  else
    {
      Q_EMIT new_tx_frequency ();
    }
}

void TestConfiguration::impl::sync_rig ()
{
  if (!updating_models_)
    {
      if (configuration_dialog_.transceiver_online (true))
        {
          if (configuration_dialog_.split_mode ())
            {
              Q_EMIT new_frequency (desired_frequency_);
              Q_EMIT new_tx_frequency (desired_frequency_ + ui_->TX_offset_spin_box->value ());
            }
          else
            {
              Q_EMIT new_frequency (desired_frequency_);
              Q_EMIT new_tx_frequency ();
            }
        }
    }
}

void TestConfiguration::impl::handle_transceiver_update (Transceiver::TransceiverState s)
{
  rig_state_ = s;

  auto model = configuration_dialog_.frequencies ();
  bool valid {false};
  for (int row = 0; row < model->rowCount (); ++row)
    {
      auto working_frequency = model->data (model->index (row, 0), Qt::UserRole + 1).value<Frequency> ();
      if (std::abs (static_cast<Radio::FrequencyDelta> (working_frequency - s.frequency ())) < 10000)
        {
          valid = true;
        }
    }
  if (!valid)
    {
      ui_->vfo_0_lcd_number->setStyleSheet ("QLCDNumber {background-color: red;}");
    }
  else
    {
      ui_->vfo_0_lcd_number->setStyleSheet (QString {});
    }

  ui_->vfo_0_lcd_number->display (Radio::pretty_frequency_MHz_string (s.frequency ()));

  if (s.split ())
    {
      ui_->vfo_1_lcd_number->display (Radio::pretty_frequency_MHz_string (s.tx_frequency ()));

      valid = false;
      for (int row = 0; row < model->rowCount (); ++row)
        {
          auto working_frequency = model->data (model->index (row, 0), Qt::UserRole + 1).value<Frequency> ();
          if (std::abs (static_cast<Radio::FrequencyDelta> (working_frequency - s.tx_frequency ())) < 10000)
            {
              valid = true;
            }
        }
      if (!valid)
        {
          ui_->vfo_1_lcd_number->setStyleSheet ("QLCDNumber {background-color: red;}");
        }
      else
        {
          ui_->vfo_1_lcd_number->setStyleSheet (QString {});
        }
      ui_->vfo_1_lcd_number->show ();
      ui_->vfo_1_TX_push_button->show ();
    }
  else
    {
      ui_->vfo_1_lcd_number->hide ();
      ui_->vfo_1_TX_push_button->hide ();
    }

  frequency_changed (s.frequency ());

  ui_->radio_widget->setEnabled (s.online ());

  ui_->mode_combo_box->setCurrentIndex (s.mode ());

  RX_frequency_.setText (Radio::pretty_frequency_MHz_string (s.frequency ()));
  TX_frequency_.setText (Radio::pretty_frequency_MHz_string (s.split () ? s.tx_frequency () : s.frequency ()));

  ui_->TX_button_group->button (s.split ())->setChecked (true);

  ui_->PTT_push_button->setChecked (s.ptt ());

  ui_->split_push_button->setChecked (s.split ());

  ui_->radio_widget->setEnabled (s.online ());
}

void TestConfiguration::impl::handle_transceiver_failure (QString reason)
{
  ui_->radio_widget->setEnabled (false);

  ui_->vfo_0_lcd_number->display (LCD_error);
  ui_->vfo_1_lcd_number->display (LCD_error);
  information_message_box ("Rig failure", reason);
}

void TestConfiguration::impl::read_settings ()
{
  settings_->beginGroup ("TestConfiguration");
  resize (settings_->value ("window/size", size ()).toSize ());
  move (settings_->value ("window/pos", pos ()).toPoint ());
  restoreState (settings_->value ("window/state", saveState ()).toByteArray ());
  ui_->band_combo_box->setCurrentText (settings_->value ("Band").toString ());
  settings_->endGroup ();

  settings_->beginGroup ("Configuration");
  callsign_ = settings_->value ("MyCall").toString ();
  settings_->endGroup ();
}

void TestConfiguration::impl::write_settings ()
{
  settings_->beginGroup ("TestConfiguration");
  settings_->setValue ("window/size", size ());
  settings_->setValue ("window/pos", pos ());
  settings_->setValue ("window/state", saveState ());
  settings_->setValue ("Band", ui_->band_combo_box->currentText ());
  settings_->endGroup ();
}

void TestConfiguration::impl::load_models ()
{
  updating_models_ = true;

  ui_->frequency_group_box->setTitle (configuration_dialog_.rig_name ());
  // if (auto rig = configuration_dialog_.rig (false)) // don't open radio
  if (configuration_dialog_.transceiver_online (false)) // don't open radio
    {
      Q_EMIT configuration_dialog_.sync_transceiver (true);
    }
  else
    {
      ui_->radio_widget->setEnabled (false);
      ui_->vfo_0_lcd_number->display (Radio::pretty_frequency_MHz_string (static_cast<Frequency> (0)));
      ui_->vfo_1_lcd_number->display (Radio::pretty_frequency_MHz_string (static_cast<Frequency> (0)));
    }

  if (!configuration_dialog_.split_mode ())
    {
      ui_->vfo_1_lcd_number->hide ();
      ui_->vfo_1_TX_push_button->hide ();
    }

  updating_models_ = false;
}

void TestConfiguration::impl::information_message_box (QString const& reason, QString const& detail)
{
  qDebug () << "TestConfiguration::information_message_box: reason =" << reason << "detail =" << detail;
  QMessageBox mb;
  mb.setWindowFlags (mb.windowFlags () | Qt::WindowStaysOnTopHint | Qt::X11BypassWindowManagerHint);
  mb.setText (reason);
  if (!detail.isEmpty ())
    {
      mb.setDetailedText (detail);
    }
  mb.setStandardButtons (QMessageBox::Ok);
  mb.setDefaultButton (QMessageBox::Ok);
  mb.setIcon (QMessageBox::Information);
  mb.exec ();
}
