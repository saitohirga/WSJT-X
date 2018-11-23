#include "FoxLogWindow.hpp"

#include <QApplication>

#include "SettingsGroup.hpp"
#include "Configuration.hpp"
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
  explicit impl () = default;
  Ui::FoxLogWindow ui_;
};

FoxLogWindow::FoxLogWindow (QSettings * settings, Configuration const * configuration
                            , QAbstractItemModel * fox_log_model, QWidget * parent)
  : AbstractLogWindow {"Fox Log Window", settings, configuration, parent}
{
  setWindowTitle (QApplication::applicationName () + " - Fox Log");
  m_->ui_.setupUi (this);
  set_log_model (fox_log_model);
  set_log_view (m_->ui_.log_table_view);
  m_->ui_.log_table_view->setItemDelegateForColumn (1, new DateTimeAsSecsSinceEpochDelegate {this});
  m_->ui_.log_table_view->setItemDelegateForColumn (2, new CallsignDelegate {this});
  m_->ui_.log_table_view->setItemDelegateForColumn (3, new MaidenheadLocatorDelegate {this});
  m_->ui_.log_table_view->setItemDelegateForColumn (6, new ForeignKeyDelegate {configuration->bands (), fox_log_model, 0, 6, this});
  m_->ui_.log_table_view->horizontalHeader ()->moveSection (6, 1); // move band to first column
  m_->ui_.rate_label->setNum (0);
  m_->ui_.queued_label->setNum (0);
  m_->ui_.callers_label->setNum (0);
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
