#include "MessageAggregatorMainWindow.hpp"

#include <QtWidgets>
#include <QDateTime>

#include "DecodesModel.hpp"
#include "BeaconsModel.hpp"
#include "ClientWidget.hpp"

using port_type = MessageServer::port_type;

namespace
{
  char const * const headings[] = {
    QT_TRANSLATE_NOOP ("MessageAggregatorMainWindow", "Date/Time"),
    QT_TRANSLATE_NOOP ("MessageAggregatorMainWindow", "Callsign"),
    QT_TRANSLATE_NOOP ("MessageAggregatorMainWindow", "Grid"),
    QT_TRANSLATE_NOOP ("MessageAggregatorMainWindow", "Name"),
    QT_TRANSLATE_NOOP ("MessageAggregatorMainWindow", "Frequency"),
    QT_TRANSLATE_NOOP ("MessageAggregatorMainWindow", "Mode"),
    QT_TRANSLATE_NOOP ("MessageAggregatorMainWindow", "Sent"),
    QT_TRANSLATE_NOOP ("MessageAggregatorMainWindow", "Rec'd"),
    QT_TRANSLATE_NOOP ("MessageAggregatorMainWindow", "Power"),
    QT_TRANSLATE_NOOP ("MessageAggregatorMainWindow", "Comments"),
  };
}

MessageAggregatorMainWindow::MessageAggregatorMainWindow ()
  : log_ {new QStandardItemModel {0, 10, this}}
  , decodes_model_ {new DecodesModel {this}}
  , beacons_model_ {new BeaconsModel {this}}
  , server_ {new MessageServer {this}}
  , multicast_group_line_edit_ {new QLineEdit}
  , log_table_view_ {new QTableView}
{
  // logbook
  int column {0};
  for (auto const& heading : headings)
    {
      log_->setHeaderData (column++, Qt::Horizontal, tr (heading));
    }
  connect (server_, &MessageServer::qso_logged, this, &MessageAggregatorMainWindow::log_qso);

  // menu bar
  auto file_menu = menuBar ()->addMenu (tr ("&File"));

  auto exit_action = new QAction {tr ("E&xit"), this};
  exit_action->setShortcuts (QKeySequence::Quit);
  exit_action->setToolTip (tr ("Exit the application"));
  file_menu->addAction (exit_action);
  connect (exit_action, &QAction::triggered, this, &MessageAggregatorMainWindow::close);

  view_menu_ = menuBar ()->addMenu (tr ("&View"));

  // central layout
  auto central_layout = new QVBoxLayout;

  // server details
  auto port_spin_box = new QSpinBox;
  port_spin_box->setMinimum (1);
  port_spin_box->setMaximum (std::numeric_limits<port_type>::max ());
  auto group_box_layout = new QFormLayout;
  group_box_layout->addRow (tr ("Port number:"), port_spin_box);
  group_box_layout->addRow (tr ("Multicast Group (blank for unicast server):"), multicast_group_line_edit_);
  auto group_box = new QGroupBox {tr ("Server Details")};
  group_box->setLayout (group_box_layout);
  central_layout->addWidget (group_box);

  log_table_view_->setModel (log_);
  log_table_view_->verticalHeader ()->hide ();
  central_layout->addWidget (log_table_view_);

  // central widget
  auto central_widget = new QWidget;
  central_widget->setLayout (central_layout);

  // main window setup
  setCentralWidget (central_widget);
  setDockOptions (AnimatedDocks | AllowNestedDocks | AllowTabbedDocks);
  setTabPosition (Qt::BottomDockWidgetArea, QTabWidget::North);

  // connect up server
  connect (server_, &MessageServer::error, [this] (QString const& message) {
      QMessageBox::warning (this, tr ("Network Error"), message);
    });
  connect (server_, &MessageServer::client_opened, this, &MessageAggregatorMainWindow::add_client);
  connect (server_, &MessageServer::client_closed, this, &MessageAggregatorMainWindow::remove_client);
  connect (server_, &MessageServer::client_closed, decodes_model_, &DecodesModel::clear_decodes);
  connect (server_, &MessageServer::client_closed, beacons_model_, &BeaconsModel::clear_decodes);
  connect (server_, &MessageServer::decode, decodes_model_, &DecodesModel::add_decode);
  connect (server_, &MessageServer::WSPR_decode, beacons_model_, &BeaconsModel::add_beacon_spot);
  connect (server_, &MessageServer::clear_decodes, decodes_model_, &DecodesModel::clear_decodes);
  connect (server_, &MessageServer::clear_decodes, beacons_model_, &BeaconsModel::clear_decodes);
  connect (decodes_model_, &DecodesModel::reply, server_, &MessageServer::reply);

  // UI behaviour
  connect (port_spin_box, static_cast<void (QSpinBox::*)(int)> (&QSpinBox::valueChanged)
           , [this] (port_type port) {server_->start (port);});
  connect (multicast_group_line_edit_, &QLineEdit::editingFinished, [this, port_spin_box] () {
      server_->start (port_spin_box->value (), QHostAddress {multicast_group_line_edit_->text ()});
    });

  port_spin_box->setValue (2237); // start up in unicast mode
  show ();
}

void MessageAggregatorMainWindow::log_qso (QString const& /*id*/, QDateTime time, QString const& dx_call, QString const& dx_grid
                                           , Frequency dial_frequency, QString const& mode, QString const& report_sent
                                           , QString const& report_received, QString const& tx_power, QString const& comments
                                           , QString const& name)
{
  QList<QStandardItem *> row;
  row << new QStandardItem {time.toString ("dd-MMM-yyyy hh:mm")}
  << new QStandardItem {dx_call}
  << new QStandardItem {dx_grid}
  << new QStandardItem {name}
  << new QStandardItem {Radio::frequency_MHz_string (dial_frequency)}
  << new QStandardItem {mode}
  << new QStandardItem {report_sent}
  << new QStandardItem {report_received}
  << new QStandardItem {tx_power}
  << new QStandardItem {comments};
  log_->appendRow (row);
  log_table_view_->resizeColumnsToContents ();
  log_table_view_->horizontalHeader ()->setStretchLastSection (true);
  log_table_view_->scrollToBottom ();
}

void MessageAggregatorMainWindow::add_client (QString const& id)
{
  auto dock = new ClientWidget {decodes_model_, beacons_model_, id, this};
  dock->setAttribute (Qt::WA_DeleteOnClose);
  auto view_action = dock->toggleViewAction ();
  view_action->setEnabled (true);
  view_menu_->addAction (view_action);
  addDockWidget (Qt::BottomDockWidgetArea, dock);
  connect (server_, &MessageServer::status_update, dock, &ClientWidget::update_status);
  connect (server_, &MessageServer::decode, dock, &ClientWidget::decode_added);
  connect (server_, &MessageServer::WSPR_decode, dock, &ClientWidget::beacon_spot_added);
  connect (dock, &ClientWidget::do_reply, decodes_model_, &DecodesModel::do_reply);
  connect (dock, &ClientWidget::do_halt_tx, server_, &MessageServer::halt_tx);
  connect (dock, &ClientWidget::do_free_text, server_, &MessageServer::free_text);
  connect (view_action, &QAction::toggled, dock, &ClientWidget::setVisible);
  dock_widgets_[id] = dock;
  server_->replay (id);
}

void MessageAggregatorMainWindow::remove_client (QString const& id)
{
  auto iter = dock_widgets_.find (id);
  if (iter != std::end (dock_widgets_))
    {
      (*iter)->close ();
      dock_widgets_.erase (iter);
    }
}

#include "moc_MessageAggregatorMainWindow.cpp"
