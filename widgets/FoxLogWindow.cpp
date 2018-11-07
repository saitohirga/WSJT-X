#include "FoxLogWindow.hpp"

#include <QSettings>
#include <QApplication>
#include <QDateTime>
#include <QDir>
#include <QStyledItemDelegate>
#include <QDateTimeEdit>
#include <QPainter>

#include "SettingsGroup.hpp"
#include "Configuration.hpp"
#include "models/Bands.hpp"
#include "item_delegates/ForeignKeyDelegate.hpp"
#include "widgets/MessageBox.hpp"
#include "qt_helpers.hpp"

#include "ui_FoxLogWindow.h"

namespace
{
  class DateTimeAsSecsSinceEpochItemDelegate final
    : public QStyledItemDelegate
  {
  public:
    DateTimeAsSecsSinceEpochItemDelegate (QObject * parent = nullptr)
      : QStyledItemDelegate {parent}
    {
    }

    static QVariant to_secs_since_epoch (QDateTime const& date_time)
    {
      return date_time.toMSecsSinceEpoch () / 1000;
    }

    static QDateTime to_date_time (QModelIndex const& index, int role = Qt::DisplayRole)
    {
      return to_date_time (index.model ()->data (index, role));
    }

    static QDateTime to_date_time (QVariant const& value)
    {
      return QDateTime::fromMSecsSinceEpoch (value.toULongLong () * 1000);
    }

    QString displayText (QVariant const& value, QLocale const& locale) const override
    {
      return locale.toString (to_date_time (value), QLocale::ShortFormat);
    }

    QWidget * createEditor (QWidget * parent, QStyleOptionViewItem const& /*option*/, QModelIndex const& /*index*/) const override
    {
      return new QDateTimeEdit {parent};
    }

    void setEditorData (QWidget * editor, QModelIndex const& index) const override
    {
      static_cast<QDateTimeEdit *> (editor)->setDateTime (to_date_time (index, Qt::EditRole));
    }

    void setModelData (QWidget * editor, QAbstractItemModel * model, QModelIndex const& index) const override
    {
      model->setData (index, to_secs_since_epoch (static_cast<QDateTimeEdit *> (editor)->dateTime ()));
    }

    void updateEditorGeometry (QWidget * editor, QStyleOptionViewItem const& option, QModelIndex const& /*index*/) const override
    {
      editor->setGeometry (option.rect);
    }
  };
}

FoxLogWindow::FoxLogWindow (QSettings * settings, Configuration const * configuration
                            , QAbstractItemModel * fox_log_model, QWidget * parent)
  : QWidget {parent}
  , settings_ {settings}
  , configuration_ {configuration}
  , ui_ {new Ui::FoxLogWindow}
{
  fox_log_model_.setSourceModel (fox_log_model);
  setWindowTitle (QApplication::applicationName () + " - Fox Log");
  ui_->setupUi (this);
  read_settings ();
  change_font (configuration_->decoded_text_font ());
  ui_->log_table_view->setModel (&fox_log_model_);
  ui_->log_table_view->setColumnHidden (0, true);
  ui_->log_table_view->setItemDelegateForColumn (1, new DateTimeAsSecsSinceEpochItemDelegate {this});
  ui_->log_table_view->setItemDelegateForColumn (6,  new ForeignKeyDelegate {configuration_->bands (), &fox_log_model_, 0, 6, this});
  ui_->log_table_view->setSelectionMode (QTableView::SingleSelection);
  ui_->log_table_view->resizeColumnsToContents ();
  ui_->rate_label->setNum (0);
  ui_->queued_label->setNum (0);
  ui_->callers_label->setNum (0);
  connect (&fox_log_model_, &QAbstractItemModel::rowsInserted, [this] (QModelIndex const& parent, int first, int /*last*/) {
      ui_->log_table_view->scrollTo (fox_log_model_.index (first, 0, parent));
      ui_->log_table_view->resizeColumnsToContents ();
      // ui_->log_table_view->scrollToBottom ();
    });
}

FoxLogWindow::~FoxLogWindow ()
{
  if (isVisible ())
    {
      write_settings ();
    }
}

void FoxLogWindow::closeEvent (QCloseEvent * e)
{
  write_settings ();
  QWidget::closeEvent (e);
}

void FoxLogWindow::read_settings ()
{
  SettingsGroup g {settings_, "Fox Log Window"};
  restoreGeometry (settings_->value ("window/geometery").toByteArray ());
}

void FoxLogWindow::write_settings () const
{
  SettingsGroup g {settings_, "Fox Log Window"};
  settings_->setValue ("window/geometery", saveGeometry ());
}

void FoxLogWindow::change_font (QFont const& font)
{
  // ui_->log_table_view->setFont (font);
  // ui_->log_table_view->horizontalHeader ()->setFont (font);
  // ui_->log_table_view->verticalHeader ()->setFont (font);
  fox_log_model_.set_font (font);
}

void FoxLogWindow::callers (int n)
{
  ui_->callers_label->setNum (n);
}

void FoxLogWindow::queued (int n)
{
  ui_->queued_label->setNum (n);
}

void FoxLogWindow::rate (int n)
{
  ui_->rate_label->setNum (n);
}
