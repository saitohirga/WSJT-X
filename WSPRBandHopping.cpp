#include "WSPRBandHopping.hpp"

#include <QPointer>
#include <QSettings>
#include <QBitArray>
#include <QList>
#include <QtWidgets>

#include "SettingsGroup.hpp"
#include "Configuration.hpp"
#include "Bands.hpp"
#include "FrequencyList.hpp"
#include "WsprTxScheduler.h"
#include "pimpl_impl.hpp"
#include "moc_WSPRBandHopping.cpp"

extern "C"
{
#ifndef CMAKE_BUILD
#define FC_grayline grayline_
#else
#include "FC.h"
  void FC_grayline (int const * year, int const * month, int const * nday, float const * uth, char const * my_grid
                   , int const * nduration, int * isun
                   , int my_grid_len);
#endif
};

namespace
{
  char const * const title = "WSPR Band Hopping";
  char const * const periods[] = {"Sunrise grayline", "Day", "Sunset grayline", "Night", "Tune", "Rx only"};
  size_t constexpr num_periods {sizeof (periods) / sizeof (periods[0])};
  // These 10 bands are globally coordinated
  QList<QString> const coordinated_bands = {"160m", "80m", "60m", "40m", "30m", "20m", "17m", "15m", "12m", "10m"};
}

//
// Dialog - maintenance of band hopping options
//
class Dialog
  : public QDialog
{
public:
  using BandList = QList<QString>;

  Dialog (QSettings *, Configuration const *, BandList const * WSPT_bands, QBitArray * bands
          , int * gray_line_duration, QWidget * parent = nullptr);
  ~Dialog ();

  Q_SLOT void frequencies_changed ();
  void resize_to_maximum ();

private:
  void closeEvent (QCloseEvent *) override;
  void save_window_state ();

  QSettings * settings_;
  Configuration const * configuration_;
  BandList const * WSPR_bands_;
  QBitArray * bands_;
  int * gray_line_duration_;
  QPointer<QTableWidget> bands_table_;
  QBrush coord_background_brush_;
  QPointer<QSpinBox> gray_line_width_spin_box_;
  static int const band_index_role {Qt::UserRole};
};

Dialog::Dialog (QSettings * settings, Configuration const * configuration, BandList const * WSPR_bands
                , QBitArray * bands, int * gray_line_duration, QWidget * parent)
  : QDialog {parent, Qt::WindowTitleHint | Qt::WindowCloseButtonHint}
  , settings_ {settings}
  , configuration_ {configuration}
  , WSPR_bands_ {WSPR_bands}
  , bands_ {bands}
  , gray_line_duration_ {gray_line_duration}
  , bands_table_ {new QTableWidget {this}}
  , coord_background_brush_ {Qt::yellow}
  , gray_line_width_spin_box_ {new QSpinBox {this}}
{
  setWindowTitle (windowTitle () + ' ' + tr (title));
  {
    SettingsGroup g {settings_, title};
    restoreGeometry (settings_->value ("geometry", saveGeometry ()).toByteArray ());
  }

  QVBoxLayout * main_layout {new QVBoxLayout};

  bands_table_->setRowCount (num_periods);
  bands_table_->setVerticalScrollBarPolicy (Qt::ScrollBarAlwaysOff);
  bands_table_->setHorizontalScrollBarPolicy (Qt::ScrollBarAlwaysOff);
  bands_table_->setSizePolicy (QSizePolicy::Expanding, QSizePolicy::Expanding);
  frequencies_changed ();
  main_layout->addWidget (bands_table_);
  // recalculate table when frequencies change
  connect (configuration_->frequencies (), &QAbstractItemModel::layoutChanged
           , this, &Dialog::frequencies_changed);
  // handle changes by updating the underlying flags
  connect (bands_table_.data (), &QTableWidget::itemChanged, [this] (QTableWidgetItem * item) {
      auto band_number = item->data (band_index_role).toInt ();
      bands_[item->row ()].setBit (band_number, Qt::Checked == item->checkState ());
    });

  // set up the gray line duration spin box
  gray_line_width_spin_box_->setRange (1, 60 * 2);
  gray_line_width_spin_box_->setSuffix ("min");
  gray_line_width_spin_box_->setValue (*gray_line_duration_);
  QFormLayout * form_layout = new QFormLayout;
  form_layout->addRow (tr ("Gray time:"), gray_line_width_spin_box_);
  connect (gray_line_width_spin_box_.data ()
           , static_cast<void (QSpinBox::*) (int)> (&QSpinBox::valueChanged)
           , [this] (int new_value) {*gray_line_duration_ = new_value;});

  QHBoxLayout * bottom_layout = new QHBoxLayout;
  bottom_layout->addStretch ();
  bottom_layout->addLayout (form_layout);
  main_layout->addLayout (bottom_layout);

  setLayout (main_layout);
}

Dialog::~Dialog ()
{
  // do this here too because ESC or parent shutdown closing this
  // window doesn't queue a close event
  save_window_state ();
}

void Dialog::closeEvent (QCloseEvent * e)
{
  save_window_state ();
  QDialog::closeEvent (e);
}

void Dialog::save_window_state ()
{
  SettingsGroup g {settings_, title};
  settings_->setValue ("geometry", saveGeometry ());
}

void Dialog::frequencies_changed ()
{
  bands_table_->setColumnCount (WSPR_bands_->size ());
  // set up and load the table of check boxes
  for (auto row = 0u; row < num_periods; ++row)
    {
      auto vertical_header = new QTableWidgetItem {periods[row]};
      vertical_header->setTextAlignment (Qt::AlignRight | Qt::AlignVCenter);
      bands_table_->setVerticalHeaderItem (row, vertical_header);
      int column {0};
      int band_number {0};
      for (auto const& band : *configuration_->bands ())
        {
          if (WSPR_bands_->contains (band))
            {
              if (0 == row)
                {
                  auto horizontal_header = new QTableWidgetItem {band};
                  bands_table_->setHorizontalHeaderItem (column, horizontal_header);
                }
              auto item = new QTableWidgetItem;
              item->setFlags (Qt::ItemIsUserCheckable | Qt::ItemIsEnabled);
              item->setCheckState (bands_[row].testBit (band_number) ? Qt::Checked : Qt::Unchecked);
              item->setData (band_index_role, band_number);
              if (coordinated_bands.contains (band))
                {
                  item->setBackground (coord_background_brush_);
                }
              bands_table_->setItem (row, column, item);
              ++column;
            }
          ++band_number;
        }
    }
  bands_table_->resizeColumnsToContents ();
  auto is_visible = isVisible ();
  show ();
  resize_to_maximum ();
  adjustSize ();   // fix the size
  if (!is_visible)
    {
      hide ();
    }
}

// to get the dialog window exactly the right size to contain the
// widgets without needing scroll bars we need to measure the size of
// the table widget and set its minimum size to the measured size
void Dialog::resize_to_maximum ()
{
  bands_table_->setMinimumSize ({
      bands_table_->horizontalHeader ()->length ()
        + bands_table_->verticalHeader ()->width ()
        + 2 * bands_table_->frameWidth ()
      , bands_table_->verticalHeader ()->length ()
        + bands_table_->horizontalHeader ()->height ()
        + 2 * bands_table_->frameWidth ()
    });
  bands_table_->setMaximumSize (bands_table_->minimumSize ());
}

class WSPRBandHopping::impl
{
public:
  using BandList = Dialog::BandList;

  impl (QSettings * settings, Configuration const * configuration, QWidget * parent_widget)
    : settings_ {settings}
    , configuration_ {configuration}
    , tx_percent_ {0}
    , parent_widget_ {parent_widget}
  {
    auto num_bands = configuration_->bands ()->rowCount ();
    for (auto& flags : bands_)
      {
        flags.resize (num_bands);
      }
  }

  QSettings * settings_;
  Configuration const * configuration_;
  int tx_percent_;
  BandList WSPR_bands_;
  QWidget * parent_widget_;

  // 5 x 10 bit flags representing each hopping band in each period
  // and tune
  QBitArray bands_[num_periods];

  int gray_line_duration_;
  QPointer<Dialog> dialog_;
};

WSPRBandHopping::WSPRBandHopping (QSettings * settings, Configuration const * configuration, QWidget * parent_widget)
  : m_ {settings, configuration, parent_widget}
{
  // detect changes to the working frequencies model
  m_->WSPR_bands_ = m_->configuration_->frequencies ()->all_bands (Modes::WSPR).toList ();
  connect (m_->configuration_->frequencies (), &QAbstractItemModel::layoutChanged
           , [this] () {
             m_->WSPR_bands_ = m_->configuration_->frequencies ()->all_bands (Modes::WSPR).toList ();
           });

  // load settings
  SettingsGroup g {m_->settings_, title};
  size_t size = m_->settings_->beginReadArray ("phases");
  for (auto i = 0u; i < size; ++i)
    {
      if (i < num_periods)
        {
          m_->settings_->setArrayIndex (i);
          m_->bands_[i] = m_->settings_->value ("bands").toBitArray ();
        }
    }
  m_->settings_->endArray ();
  m_->gray_line_duration_ = m_->settings_->value ("GrayLineDuration", 60).toUInt ();
}

WSPRBandHopping::~WSPRBandHopping ()
{
  // save settings
  SettingsGroup g {m_->settings_, title};
  m_->settings_->beginWriteArray ("phases");
  for (auto i = 0u; i < num_periods; ++i)
    {
      m_->settings_->setArrayIndex (i);
      m_->settings_->setValue ("bands", m_->bands_[i]);
    }
  m_->settings_->endArray ();
  m_->settings_->setValue ("GrayLineDuration", m_->gray_line_duration_);
}

// pop up the maintenance dialog window
void WSPRBandHopping::show_dialog (bool /* checked */)
{
  if (!m_->dialog_)
    {
      m_->dialog_ = new Dialog {m_->settings_, m_->configuration_, &m_->WSPR_bands_, m_->bands_
                                , &m_->gray_line_duration_, m_->parent_widget_};
    }
  m_->dialog_->show ();
  m_->dialog_->raise ();
  m_->dialog_->activateWindow ();
}

int WSPRBandHopping::tx_percent () const
{
  return m_->tx_percent_;
}

void WSPRBandHopping::set_tx_percent (int new_value)
{
  m_->tx_percent_ = new_value;
}

// determine the parameters of the hop, if any
auto WSPRBandHopping::next_hop () -> Hop
{
  auto const& now = QDateTime::currentDateTimeUtc ();
  auto const& date = now.date ();
  auto year = date.year ();
  auto month = date.month ();
  auto day = date.day ();
  auto const& time = now.time ();
  float uth = time.hour () + time.minute () / 60.
    + (time.second () + .001 * time.msec ()) / 3600.;
  auto my_grid = m_->configuration_->my_grid ();
  int period_index;
  int band_index;
  int tx_next;

  my_grid = (my_grid + "      ").left (6); // hopping doesn't like
                                           // short grids

  // look up the period for this time
  FC_grayline (&year, &month, &day, &uth, my_grid.toLatin1 ().constData ()
               , &m_->gray_line_duration_, &period_index
               , my_grid.size ());

  band_index = next_hopping_band();

  tx_next = next_is_tx ();

  int frequencies_index {-1};
  auto const& frequencies = m_->configuration_->frequencies ();
  auto const& bands = m_->configuration_->bands ();
  auto const& band_name = bands->data (bands->index (band_index + 3, 0)).toString ();
  if (m_->bands_[period_index].testBit (band_index + 3) // +3 for
                                                        // coordinated bands
      && m_->WSPR_bands_.contains (band_name))
    {
      // here we have a band that has been enabled in the hopping
      // matrix so check it it has a configured working frequency
      frequencies_index = frequencies->best_working_frequency (band_name);
    }

  // if we do not have a configured working frequency we next check
  // for a random selection from the other enabled bands in the
  // bands matrix
  if (frequencies_index < 0)
    {
      Dialog::BandList target_bands {m_->WSPR_bands_};
      // // remove all coordinated bands here since they are
      // // scheduled above and including them in the random choice will
      // // give them a biased weighting
      // for (auto const& band : coordinated_bands)
      //   {
      //     target_bands.removeOne (band);
      //   }

      // remove bands that are not enabled for hopping
      for (auto i = 0; i < m_->bands_[period_index].size (); ++i)
        {
          if (!m_->bands_[period_index].testBit (i))
            {
              target_bands.removeOne (bands->data (bands->index (i, 0)).toString ());
            }
        }

      auto num_bands = target_bands.size ();
      if (num_bands)            // we have some extra bands available
        {
          int target_index = static_cast<int> (qrand () % num_bands); // random choice
          // here we have a random choice that is enabled in the
          // hopping matrix
          frequencies_index = frequencies->best_working_frequency (target_bands[target_index]);
          if (frequencies_index >= 0)
            {
              // we can use the random choice
              qDebug () << "random:" << frequencies->data (frequencies->index (frequencies_index, FrequencyList::frequency_column)).toString ();
              band_index = bands->find (target_bands[target_index]);
              if (band_index < 0)
                {
                  // this shouldn't happen
                  Q_ASSERT (band_index >= 0);
                  frequencies_index = -1;
                }
            }
        }
    }
  else
    {
      band_index += 3;
      qDebug () << "scheduled:" << frequencies->data (frequencies->index (frequencies_index, FrequencyList::frequency_column)).toString ();
    }

  return {
    periods[period_index]

    , frequencies_index

    , frequencies_index >= 0  // new band
      && !tx_next               // not going to Tx anyway
      && m_->bands_[4].testBit (band_index) // tune up required
      && !m_->bands_[5].testBit (band_index) // not an Rx only band

    , frequencies_index >= 0  // new band
      && tx_next                // Tx scheduled
      && !m_->bands_[5].testBit (band_index) // not an Rx only band
   };
}

bool WSPRBandHopping::next_is_tx ()
{
  if (100 == m_->tx_percent_)
    {
      return true;
    }
  else
    {
      // consult scheduler to determine if next period should be a tx interval
      return next_tx_state(m_->tx_percent_);
    }
}
