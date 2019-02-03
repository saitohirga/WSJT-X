#ifndef WSJTX_UDP_CLIENT_WIDGET_MODEL_HPP__
#define WSJTX_UDP_CLIENT_WIDGET_MODEL_HPP__

#include <QObject>
#include <QSortFilterProxyModel>
#include <QString>
#include <QRegularExpression>
#include <QtWidgets>

#include "MessageServer.hpp"

class QAbstractItemModel;
class QModelIndex;
class QColor;
class QAction;

using Frequency = MessageServer::Frequency;

class ClientWidget
  : public QDockWidget
{
  Q_OBJECT;

public:
  explicit ClientWidget (QAbstractItemModel * decodes_model, QAbstractItemModel * beacons_model
                         , QString const& id, QString const& version, QString const& revision
                         , QListWidget const * calls_of_interest, QWidget * parent = nullptr);
  ~ClientWidget ();

  bool fast_mode () const {return fast_mode_;}

  Q_SLOT void update_status (QString const& id, Frequency f, QString const& mode, QString const& dx_call
                             , QString const& report, QString const& tx_mode, bool tx_enabled
                             , bool transmitting, bool decoding, qint32 rx_df, qint32 tx_df
                             , QString const& de_call, QString const& de_grid, QString const& dx_grid
                             , bool watchdog_timeout, QString const& sub_mode, bool fast_mode
                             , quint8 special_op_mode);
  Q_SLOT void decode_added (bool is_new, QString const& client_id, QTime, qint32 snr
                            , float delta_time, quint32 delta_frequency, QString const& mode
                            , QString const& message, bool low_confidence, bool off_air);
  Q_SLOT void beacon_spot_added (bool is_new, QString const& client_id, QTime, qint32 snr
                                 , float delta_time, Frequency delta_frequency, qint32 drift
                                 , QString const& callsign, QString const& grid, qint32 power
                                 , bool off_air);
  Q_SLOT void decodes_cleared (QString const& client_id);

  Q_SIGNAL void do_clear_decodes (QString const& id, quint8 window = 0);
  Q_SIGNAL void do_reply (QModelIndex const&, quint8 modifier);
  Q_SIGNAL void do_halt_tx (QString const& id, bool auto_only);
  Q_SIGNAL void do_free_text (QString const& id, QString const& text, bool);
  Q_SIGNAL void location (QString const& id, QString const& text);
  Q_SIGNAL void highlight_callsign (QString const& id, QString const& call
                                    , QColor const& bg = QColor {}, QColor const& fg = QColor {}
                                    , bool last_only = false);

private:
  QString id_;
  QListWidget const * calls_of_interest_;
  class IdFilterModel final
    : public QSortFilterProxyModel
  {
  public:
    IdFilterModel (QString const& client_id);

    void de_call (QString const&);
    void rx_df (int);

    QVariant data (QModelIndex const& proxy_index, int role = Qt::DisplayRole) const override;

  protected:
    bool filterAcceptsRow (int source_row, QModelIndex const& source_parent) const override;

  private:
    QString client_id_;
    QString call_;
    QRegularExpression base_call_re_;
    int rx_df_;
  } decodes_proxy_model_;
  QAction * erase_action_;
  QAction * erase_rx_frequency_action_;
  QAction * erase_both_action_;
  QTableView * decodes_table_view_;
  QTableView * beacons_table_view_;
  QLineEdit * message_line_edit_;
  QLineEdit * grid_line_edit_;
  QStackedLayout * decodes_stack_;
  QAbstractButton * auto_off_button_;
  QAbstractButton * halt_tx_button_;
  QLabel * de_label_;
  QLabel * mode_label_;
  bool fast_mode_;
  QLabel * frequency_label_;
  QLabel * dx_label_;
  QLabel * rx_df_label_;
  QLabel * tx_df_label_;
  QLabel * report_label_;
  bool columns_resized_;
};

#endif
