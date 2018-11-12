#include "CabrilloLogWindow.hpp"

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
#include "item_delegates/DateTimeAsSecsSinceEpochDelegate.hpp"
#include "item_delegates/CallsignDelegate.hpp"
#include "item_delegates/MaidenheadLocatorDelegate.hpp"
#include "widgets/MessageBox.hpp"
#include "qt_helpers.hpp"

#include "ui_CabrilloLogWindow.h"

CabrilloLogWindow::CabrilloLogWindow (QSettings * settings, Configuration const * configuration
                            , QAbstractItemModel * cabrillo_log_model, QWidget * parent)
  : QWidget {parent}
  , settings_ {settings}
  , configuration_ {configuration}
  , ui_ {new Ui::CabrilloLogWindow}
{
  cabrillo_log_model_.setSourceModel (cabrillo_log_model);
  setWindowTitle (QApplication::applicationName () + " - Cabrillo Log");
  ui_->setupUi (this);
  read_settings ();
  change_font (configuration_->decoded_text_font ());
  ui_->log_table_view->setModel (&cabrillo_log_model_);
  ui_->log_table_view->setColumnHidden (0, true);
  ui_->log_table_view->setItemDelegateForColumn (2, new DateTimeAsSecsSinceEpochDelegate {this});
  ui_->log_table_view->setItemDelegateForColumn (3, new CallsignDelegate {this});
  ui_->log_table_view->setItemDelegateForColumn (6, new ForeignKeyDelegate {configuration_->bands (), &cabrillo_log_model_, 0, 6, this});
  ui_->log_table_view->setSelectionMode (QTableView::SingleSelection);
  auto horizontal_header = ui_->log_table_view->horizontalHeader ();
  horizontal_header->setStretchLastSection (true);
  horizontal_header->setSectionResizeMode (QHeaderView::ResizeToContents);
  horizontal_header->setSectionsMovable (true);
  horizontal_header->moveSection (6, 1); // band to first column
  ui_->log_table_view->scrollToBottom ();

  // ensure view scrolls to latest new row
  connect (&cabrillo_log_model_, &QAbstractItemModel::rowsInserted, [this] (QModelIndex const& /*parent*/, int /*first*/, int /*last*/) {
      ui_->log_table_view->scrollToBottom ();
    });
}

CabrilloLogWindow::~CabrilloLogWindow ()
{
  write_settings ();
}

void CabrilloLogWindow::read_settings ()
{
  SettingsGroup g {settings_, "Cabrillo Log Window"};
  restoreGeometry (settings_->value ("window/geometery").toByteArray ());
}

void CabrilloLogWindow::write_settings () const
{
  SettingsGroup g {settings_, "Cabrillo Log Window"};
  settings_->setValue ("window/geometery", saveGeometry ());
}

void CabrilloLogWindow::change_font (QFont const& font)
{
  // ui_->log_table_view->setFont (font);
  // ui_->log_table_view->horizontalHeader ()->setFont (font);
  // ui_->log_table_view->verticalHeader ()->setFont (font);
  cabrillo_log_model_.set_font (font);
}
