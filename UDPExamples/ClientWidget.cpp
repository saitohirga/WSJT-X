#include "ClientWidget.hpp"

#include <QRegExp>
#include <QColor>
#include <QAction>

#include "validators/MaidenheadLocatorValidator.hpp"

namespace
{
  //QRegExp message_alphabet {"[- A-Za-z0-9+./?]*"};
  QRegExp message_alphabet {"[- @A-Za-z0-9+./?#<>]*"};
  QRegularExpression cq_re {"(CQ|CQDX|QRZ)[^A-Z0-9/]+"};

  void update_dynamic_property (QWidget * widget, char const * property, QVariant const& value)
  {
    widget->setProperty (property, value);
    widget->style ()->unpolish (widget);
    widget->style ()->polish (widget);
    widget->update ();
  }
}

ClientWidget::IdFilterModel::IdFilterModel (QString const& client_id)
  : client_id_ {client_id}
  , rx_df_ (-1)
{
}

QVariant ClientWidget::IdFilterModel::data (QModelIndex const& proxy_index, int role) const
{
  if (role == Qt::BackgroundRole)
    {
      switch (proxy_index.column ())
        {
        case 8:                 // message
          {
            auto message = QSortFilterProxyModel::data (proxy_index).toString ();
            if (base_call_re_.pattern ().size ()
                && message.contains (base_call_re_))
              {
                return QColor {255,200,200};
              }
            if (message.contains (cq_re))
              {
                return QColor {200, 255, 200};
              }
          }
          break;

        case 4:                 // DF
          if (qAbs (QSortFilterProxyModel::data (proxy_index).toInt () - rx_df_) <= 10)
            {
              return QColor {255, 200, 200};
            }
          break;

        default:
          break;
        }
    }
  return QSortFilterProxyModel::data (proxy_index, role);
}

bool ClientWidget::IdFilterModel::filterAcceptsRow (int source_row
                                                    , QModelIndex const& source_parent) const
{
  auto source_index_col0 = sourceModel ()->index (source_row, 0, source_parent);
  return sourceModel ()->data (source_index_col0).toString () == client_id_;
}

void ClientWidget::IdFilterModel::de_call (QString const& call)
{
  if (call != call_)
    {
      beginResetModel ();
      if (call.size ())
        {
          base_call_re_.setPattern ("[^A-Z0-9]*" + Radio::base_callsign (call) + "[^A-Z0-9]*");
        }
      else
        {
          base_call_re_.setPattern (QString {});
        }
      call_ = call;
      endResetModel ();
    }
}

void ClientWidget::IdFilterModel::rx_df (int df)
{
  if (df != rx_df_)
    {
      beginResetModel ();
      rx_df_ = df;
      endResetModel ();
    }
}

namespace
{
  QString make_title (QString const& id, QString const& version, QString const& revision)
  {
    QString title {id};
    if (version.size ())
      {
        title += QString {" v%1"}.arg (version);
      }
    if (revision.size ())
      {
        title += QString {" (%1)"}.arg (revision);
      }
    return title;
  }
}

ClientWidget::ClientWidget (QAbstractItemModel * decodes_model, QAbstractItemModel * beacons_model
                            , QString const& id, QString const& version, QString const& revision
                            , QListWidget const * calls_of_interest, QWidget * parent)
  : QDockWidget {make_title (id, version, revision), parent}
  , id_ {id}
  , calls_of_interest_ {calls_of_interest}
  , decodes_proxy_model_ {id_}
  , erase_action_ {new QAction {tr ("&Erase Band Activity"), this}}
  , erase_rx_frequency_action_ {new QAction {tr ("Erase &Rx Frequency"), this}}
  , erase_both_action_ {new QAction {tr ("Erase &Both"), this}}
  , decodes_table_view_ {new QTableView}
  , beacons_table_view_ {new QTableView}
  , message_line_edit_ {new QLineEdit}
  , grid_line_edit_ {new QLineEdit}
  , decodes_stack_ {new QStackedLayout}
  , auto_off_button_ {new QPushButton {tr ("&Auto Off")}}
  , halt_tx_button_ {new QPushButton {tr ("&Halt Tx")}}
  , de_label_ {new QLabel}
  , mode_label_ {new QLabel}
  , fast_mode_ {false}
  , frequency_label_ {new QLabel}
  , dx_label_ {new QLabel}
  , rx_df_label_ {new QLabel}
  , tx_df_label_ {new QLabel}
  , report_label_ {new QLabel}
  , columns_resized_ {false}
{
  // set up widgets
  decodes_proxy_model_.setSourceModel (decodes_model);
  decodes_table_view_->setModel (&decodes_proxy_model_);
  decodes_table_view_->verticalHeader ()->hide ();
  decodes_table_view_->hideColumn (0);
  decodes_table_view_->horizontalHeader ()->setStretchLastSection (true);
  decodes_table_view_->setContextMenuPolicy (Qt::ActionsContextMenu);
  decodes_table_view_->insertAction (nullptr, erase_action_);
  decodes_table_view_->insertAction (nullptr, erase_rx_frequency_action_);
  decodes_table_view_->insertAction (nullptr, erase_both_action_);

  auto form_layout = new QFormLayout;
  form_layout->addRow (tr ("Free text:"), message_line_edit_);
  form_layout->addRow (tr ("Temporary grid:"), grid_line_edit_);
  message_line_edit_->setValidator (new QRegExpValidator {message_alphabet, this});
  grid_line_edit_->setValidator (new MaidenheadLocatorValidator {this});
  connect (message_line_edit_, &QLineEdit::textEdited, [this] (QString const& text) {
      Q_EMIT do_free_text (id_, text, false);
    });
  connect (message_line_edit_, &QLineEdit::editingFinished, [this] () {
      Q_EMIT do_free_text (id_, message_line_edit_->text (), true);
    });
  connect (grid_line_edit_, &QLineEdit::editingFinished, [this] () {
      Q_EMIT location (id_, grid_line_edit_->text ());
  });

  auto decodes_page = new QWidget;
  auto decodes_layout = new QVBoxLayout {decodes_page};
  decodes_layout->setContentsMargins (QMargins {2, 2, 2, 2});
  decodes_layout->addWidget (decodes_table_view_);
  decodes_layout->addLayout (form_layout);

  auto beacons_proxy_model = new IdFilterModel {id_};
  beacons_proxy_model->setSourceModel (beacons_model);
  beacons_table_view_->setModel (beacons_proxy_model);
  beacons_table_view_->verticalHeader ()->hide ();
  beacons_table_view_->hideColumn (0);
  beacons_table_view_->horizontalHeader ()->setStretchLastSection (true);
  beacons_table_view_->setContextMenuPolicy (Qt::ActionsContextMenu);
  beacons_table_view_->insertAction (nullptr, erase_action_);

  auto beacons_page = new QWidget;
  auto beacons_layout = new QVBoxLayout {beacons_page};
  beacons_layout->setContentsMargins (QMargins {2, 2, 2, 2});
  beacons_layout->addWidget (beacons_table_view_);

  decodes_stack_->addWidget (decodes_page);
  decodes_stack_->addWidget (beacons_page);

  // stack alternative views
  auto content_layout = new QVBoxLayout;
  content_layout->setContentsMargins (QMargins {2, 2, 2, 2});
  content_layout->addLayout (decodes_stack_);

  // set up controls
  auto control_button_box = new QDialogButtonBox;
  control_button_box->addButton (auto_off_button_, QDialogButtonBox::ActionRole);
  control_button_box->addButton (halt_tx_button_, QDialogButtonBox::ActionRole);
  connect (auto_off_button_, &QAbstractButton::clicked, [this] (bool /* checked */) {
      Q_EMIT do_halt_tx (id_, true);
    });
  connect (halt_tx_button_, &QAbstractButton::clicked, [this] (bool /* checked */) {
      Q_EMIT do_halt_tx (id_, false);
    });
  content_layout->addWidget (control_button_box);

  // set up status area
  auto status_bar = new QStatusBar;
  status_bar->addPermanentWidget (de_label_);
  status_bar->addPermanentWidget (mode_label_);
  status_bar->addPermanentWidget (frequency_label_);
  status_bar->addPermanentWidget (dx_label_);
  status_bar->addPermanentWidget (rx_df_label_);
  status_bar->addPermanentWidget (tx_df_label_);
  status_bar->addPermanentWidget (report_label_);
  content_layout->addWidget (status_bar);
  connect (this, &ClientWidget::topLevelChanged, status_bar, &QStatusBar::setSizeGripEnabled);

  // set up central widget
  auto content_widget = new QFrame;
  content_widget->setFrameStyle (QFrame::StyledPanel | QFrame::Sunken);
  content_widget->setLayout (content_layout);
  setWidget (content_widget);
  // setMinimumSize (QSize {550, 0});
  setFeatures (DockWidgetMovable | DockWidgetFloatable);
  setAllowedAreas (Qt::BottomDockWidgetArea);
  setFloating (true);

  // connect context menu actions
  connect (erase_action_, &QAction::triggered, [this] (bool /*checked*/) {
      Q_EMIT do_clear_decodes (id_);
    });
  connect (erase_rx_frequency_action_, &QAction::triggered, [this] (bool /*checked*/) {
      Q_EMIT do_clear_decodes (id_, 1);
    });
  connect (erase_both_action_, &QAction::triggered, [this] (bool /*checked*/) {
      Q_EMIT do_clear_decodes (id_, 2);
    });

  // connect up table view signals
  connect (decodes_table_view_, &QTableView::doubleClicked, [this] (QModelIndex const& index) {
      Q_EMIT do_reply (decodes_proxy_model_.mapToSource (index), QApplication::keyboardModifiers () >> 24);
    });

  // tell new client about calls of interest
  for (int row = 0; row < calls_of_interest_->count (); ++row)
    {
      Q_EMIT highlight_callsign (id_, calls_of_interest_->item (row)->text (), QColor {Qt::blue}, QColor {Qt::yellow});
    }
}

ClientWidget::~ClientWidget ()
{
  for (int row = 0; row < calls_of_interest_->count (); ++row)
    {
      // tell client to forget calls of interest
      Q_EMIT highlight_callsign (id_, calls_of_interest_->item (row)->text ());
    }
}

void ClientWidget::update_status (QString const& id, Frequency f, QString const& mode, QString const& dx_call
                                  , QString const& report, QString const& tx_mode, bool tx_enabled
                                  , bool transmitting, bool decoding, qint32 rx_df, qint32 tx_df
                                  , QString const& de_call, QString const& de_grid, QString const& dx_grid
                                  , bool watchdog_timeout, QString const& sub_mode, bool fast_mode
                                  , quint8 special_op_mode)
{
  if (id == id_)
    {
      fast_mode_ = fast_mode;
      decodes_proxy_model_.de_call (de_call);
      decodes_proxy_model_.rx_df (rx_df);
      QString special;
      switch (special_op_mode)
        {
        case 1: special = "[NA VHF]"; break;
        case 2: special = "[EU VHF]"; break;
        case 3: special = "[FD]"; break;
        case 4: special = "[RTTY RU]"; break;
        case 5: special = "[Fox]"; break;
        case 6: special = "[Hound]"; break;
        default: break;
        }
      de_label_->setText (de_call.size () >= 0 ? QString {"DE: %1%2%3"}.arg (de_call)
                          .arg (de_grid.size () ? '(' + de_grid + ')' : QString {})
                          .arg (special)
                          : QString {});
      mode_label_->setText (QString {"Mode: %1%2%3%4"}
           .arg (mode)
           .arg (sub_mode)
           .arg (fast_mode && !mode.contains (QRegularExpression {R"(ISCAT|MSK144)"}) ? "fast" : "")
           .arg (tx_mode.isEmpty () || tx_mode == mode ? "" : '(' + tx_mode + ')'));
      frequency_label_->setText ("QRG: " + Radio::pretty_frequency_MHz_string (f));
      dx_label_->setText (dx_call.size () >= 0 ? QString {"DX: %1%2"}.arg (dx_call)
                          .arg (dx_grid.size () ? '(' + dx_grid + ')' : QString {}) : QString {});
      rx_df_label_->setText (rx_df >= 0 ? QString {"Rx: %1"}.arg (rx_df) : "");
      tx_df_label_->setText (tx_df >= 0 ? QString {"Tx: %1"}.arg (tx_df) : "");
      report_label_->setText ("SNR: " + report);
      update_dynamic_property (frequency_label_, "transmitting", transmitting);
      auto_off_button_->setEnabled (tx_enabled);
      halt_tx_button_->setEnabled (transmitting);
      update_dynamic_property (mode_label_, "decoding", decoding);
      update_dynamic_property (tx_df_label_, "watchdog_timeout", watchdog_timeout);
    }
}

void ClientWidget::decode_added (bool /*is_new*/, QString const& client_id, QTime /*time*/, qint32 /*snr*/
                                 , float /*delta_time*/, quint32 /*delta_frequency*/, QString const& /*mode*/
                                 , QString const& /*message*/, bool /*low_confidence*/, bool /*off_air*/)
{
  if (client_id == id_ && !columns_resized_)
    {
      decodes_stack_->setCurrentIndex (0);
      decodes_table_view_->resizeColumnsToContents ();
      columns_resized_ = true;
    }
  decodes_table_view_->scrollToBottom ();
}

void ClientWidget::beacon_spot_added (bool /*is_new*/, QString const& client_id, QTime /*time*/, qint32 /*snr*/
                                      , float /*delta_time*/, Frequency /*delta_frequency*/, qint32 /*drift*/
                                      , QString const& /*callsign*/, QString const& /*grid*/, qint32 /*power*/
                                      , bool /*off_air*/)
{
  if (client_id == id_ && !columns_resized_)
    {
      decodes_stack_->setCurrentIndex (1);
      beacons_table_view_->resizeColumnsToContents ();
      columns_resized_ = true;
    }
  beacons_table_view_->scrollToBottom ();
}

void ClientWidget::decodes_cleared (QString const& client_id)
{
  if (client_id == id_)
    {
      columns_resized_ = false;
    }
}

#include "moc_ClientWidget.cpp"
