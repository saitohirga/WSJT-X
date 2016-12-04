#ifndef WSJTX_MESSAGE_AGGREGATOR_MAIN_WINDOW_MODEL_HPP__
#define WSJTX_MESSAGE_AGGREGATOR_MAIN_WINDOW_MODEL_HPP__

#include <QMainWindow>
#include <QHash>
#include <QString>

#include "MessageServer.hpp"

class QDateTime;
class QStandardItemModel;
class QMenu;
class DecodesModel;
class BeaconsModel;
class QLineEdit;
class QTableView;
class ClientWidget;

using Frequency = MessageServer::Frequency;

class MessageAggregatorMainWindow
  : public QMainWindow
{
  Q_OBJECT;

public:
  MessageAggregatorMainWindow ();

  Q_SLOT void log_qso (QString const& /*id*/, QDateTime time, QString const& dx_call, QString const& dx_grid
                       , Frequency dial_frequency, QString const& mode, QString const& report_sent
                       , QString const& report_received, QString const& tx_power, QString const& comments
                       , QString const& name);

private:
  void add_client (QString const& id, QString const& version, QString const& revision);
  void remove_client (QString const& id);

  QStandardItemModel * log_;
  QMenu * view_menu_;
  DecodesModel * decodes_model_;
  BeaconsModel * beacons_model_;
  MessageServer * server_;
  QLineEdit * multicast_group_line_edit_;
  QTableView * log_table_view_;

  // maps client id to widgets
  using ClientsDictionary = QHash<QString, ClientWidget *>;
  ClientsDictionary dock_widgets_;
};

#endif
