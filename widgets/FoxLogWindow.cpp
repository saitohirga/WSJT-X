#include "FoxLogWindow.hpp"

#include <QApplication>
#include <QSqlTableModel>
#include <QAction>
#include <QFile>
#include <QDir>

#include "SettingsGroup.hpp"
#include "Configuration.hpp"
#include "MessageBox.hpp"
#include "models/Bands.hpp"
#include "item_delegates/ForeignKeyDelegate.hpp"
#include "item_delegates/DateTimeAsSecsSinceEpochDelegate.hpp"
#include "item_delegates/CallsignDelegate.hpp"
#include "item_delegates/MaidenheadLocatorDelegate.hpp"
#include "pimpl_impl.hpp"

#include "ui_FoxLogWindow.h"

class FoxLogWindow::impl final
{
public:
  explicit impl (QSqlTableModel * log_model)
    : log_model_ {log_model}
  {
  }

  QSqlTableModel * log_model_;
  Ui::FoxLogWindow ui_;
};

FoxLogWindow::FoxLogWindow (QSettings * settings, Configuration const * configuration
                            , QSqlTableModel * fox_log_model, QWidget * parent)
  : AbstractLogWindow {"Fox Log Window", settings, configuration, parent}
  , m_ {fox_log_model}
{
  setWindowTitle (QApplication::applicationName () + " - Fox Log");
  m_->ui_.setupUi (this);
  m_->ui_.log_table_view->setModel (m_->log_model_);
  set_log_view (m_->ui_.log_table_view);
  m_->ui_.log_table_view->setItemDelegateForColumn (1, new DateTimeAsSecsSinceEpochDelegate {this});
  m_->ui_.log_table_view->setItemDelegateForColumn (2, new CallsignDelegate {this});
  m_->ui_.log_table_view->setItemDelegateForColumn (3, new MaidenheadLocatorDelegate {this});
  m_->ui_.log_table_view->setItemDelegateForColumn (6, new ForeignKeyDelegate {configuration->bands (), m_->log_model_, 0, 6, this});
  m_->ui_.log_table_view->horizontalHeader ()->moveSection (6, 1); // move band to first column
  m_->ui_.rate_label->setNum (0);
  m_->ui_.queued_label->setNum (0);
  m_->ui_.callers_label->setNum (0);

  // actions
  auto reset_action = new QAction {tr ("&Reset ..."), m_->ui_.log_table_view};
  m_->ui_.log_table_view->insertAction (nullptr, reset_action);
  connect (reset_action, &QAction::triggered, [this, configuration] (bool /*checked*/) {
      if (MessageBox::Yes == MessageBox::query_message( this
                                                        , tr ("Confirm Reset")
                                                        , tr ("Are you sure you want to erase file FoxQSO.txt "
                                                              "and start a new Fox log?")))
        {
          QFile f{configuration->writeable_data_dir ().absoluteFilePath ("FoxQSO.txt")};
          f.remove ();
          Q_EMIT reset_log_model ();
        }
    });
}

FoxLogWindow::~FoxLogWindow ()
{
}

void FoxLogWindow::callers (int n)
{
  m_->ui_.callers_label->setNum (n);
}

void FoxLogWindow::queued (int n)
{
  m_->ui_.queued_label->setNum (n);
}

void FoxLogWindow::rate (int n)
{
  m_->ui_.rate_label->setNum (n);
}

void FoxLogWindow::log_model_changed (int row)
{
  if (row >= 0)
    {
      m_->log_model_->selectRow (row);
    }
  else
    {
      m_->log_model_->select ();
    }
}
