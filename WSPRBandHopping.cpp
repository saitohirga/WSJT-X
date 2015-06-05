#include "WSPRBandHopping.hpp"

#include <QPointer>
#include <QSettings>
#include <QBitArray>
#include <QtWidgets>

#include "SettingsGroup.hpp"
#include "Configuration.hpp"
#include "FrequencyList.hpp"
#include "WsprTxScheduler.h"
#include "pimpl_impl.hpp"
#include "moc_WSPRBandHopping.cpp"

extern "C"
{
#ifndef CMAKE_BUILD
#define FC_hopping hopping_
#else
#include "FC.h"
  void FC_hopping (int const * year, int const * month, int const * nday, float const * uth, char const * my_grid
                   , int const * nduration, int const * npctx, int * isun, int * iband
                   , int * ntxnext, int my_grid_len);
#endif
};

namespace
{
  // These 10 bands are the hopping candidates and are globally coordinated
  char const * const hopping_bands[] = {"160m", "80m", "60m", "40m", "30m", "20m", "17m", "15m", "12m", "10m"};
  size_t constexpr num_bands {sizeof (hopping_bands) / sizeof (hopping_bands[0])};
  char const * const periods[] = {"Sunrise grayline", "Day", "Sunset grayline", "Night", "Tune", "Rx only"};
  size_t constexpr num_periods {sizeof (periods) / sizeof (periods[0])};
  char const * const title = "WSPR Band Hopping";
}

//
// Dialog - maintenance of band hopping options
//
class Dialog
  : public QDialog
{
public:
  Dialog (QSettings *, QBitArray * bands, int * gray_line_duration, QWidget * parent = nullptr);
  ~Dialog ();

  void resize_to_maximum ();

private:
  void closeEvent (QCloseEvent *) override;
  void save_window_state ();

  QSettings * settings_;
  QBitArray * bands_;
  int * gray_line_duration_;
  QPointer<QTableWidget> bands_table_;
  QPointer<QSpinBox> gray_line_width_spin_box_;
};

Dialog::Dialog (QSettings * settings, QBitArray * bands, int * gray_line_duration, QWidget * parent)
  : QDialog {parent, Qt::WindowTitleHint | Qt::WindowCloseButtonHint}
  , settings_ {settings}
  , bands_ {bands}
  , gray_line_duration_ {gray_line_duration}
  , bands_table_ {new QTableWidget {num_periods, num_bands, this}}
  , gray_line_width_spin_box_ {new QSpinBox {this}}
{
  QVBoxLayout * main_layout {new QVBoxLayout};

  // set up and load the table of check boxes
  bands_table_->setVerticalScrollBarPolicy (Qt::ScrollBarAlwaysOff);
  bands_table_->setHorizontalScrollBarPolicy (Qt::ScrollBarAlwaysOff);
  for (auto row = 0u; row < num_periods; ++row)
    {
      auto vertical_header = new QTableWidgetItem {periods[row]};
      vertical_header->setTextAlignment (Qt::AlignRight | Qt::AlignVCenter);
      bands_table_->setVerticalHeaderItem (row, vertical_header);
      for (auto column = 0u; column < num_bands; ++column)
        {
          if (0 == row)
            {
              auto horizontal_header = new QTableWidgetItem {hopping_bands[column]};
              bands_table_->setHorizontalHeaderItem (column, horizontal_header);
            }
          auto item = new QTableWidgetItem;
          item->setFlags (Qt::ItemIsUserCheckable | Qt::ItemIsEnabled);
          item->setCheckState (bands_[row].testBit (column) ? Qt::Checked : Qt::Unchecked);
          bands_table_->setItem (row, column, item);
        }
    }
  bands_table_->resizeColumnsToContents ();
  main_layout->addWidget (bands_table_);
  // handle changes by updating the underlying flags
  connect (bands_table_.data (), &QTableWidget::itemChanged, [this] (QTableWidgetItem * item) {
      bands_[item->row ()].setBit (item->column (), Qt::Checked == item->checkState ());
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
  setWindowTitle (windowTitle () + ' ' + tr (title));
  {
    SettingsGroup g {settings_, title};
    restoreGeometry (settings_->value ("geometry", saveGeometry ()).toByteArray ());
  }
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

// to get the dialog window exactly the right size to contain the
// widgets without needing scroll bars we need to measure the size of
// the table widget and set its minimum size to the measured size
void Dialog::resize_to_maximum ()
{
  int width {bands_table_->verticalHeader ()->width ()};
  int height {bands_table_->horizontalHeader ()->height ()};
  for (auto i = 0; i < bands_table_->columnCount (); ++i)
    {
      width += bands_table_->columnWidth (i);
    }
  for (auto i = 0; i < bands_table_->rowCount (); ++i)
    {
      height += bands_table_->rowHeight (i);
    }
  bands_table_->setMinimumSize ({width, height});
}

class WSPRBandHopping::impl
{
public:
  impl (QSettings * settings, Configuration const * configuration, QWidget * parent_widget)
    : settings_ {settings}
    , configuration_ {configuration}
    , tx_percent_ {0}
    , parent_widget_ {parent_widget}
    , bands_ {
      QBitArray {num_bands},
      QBitArray {num_bands},
      QBitArray {num_bands},
      QBitArray {num_bands},
      QBitArray {num_bands},
      QBitArray {num_bands},
    }
  {
  }

  QSettings * settings_;
  Configuration const * configuration_;
  int tx_percent_;
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
  // load settings
  SettingsGroup g {m_->settings_, title};
  auto size = m_->settings_->beginReadArray ("periods");
  for (auto i = 0; i < size; ++i)
    {
      m_->settings_->setArrayIndex (i);
      m_->bands_[i] = m_->settings_->value ("bands").toBitArray ();
    }
  m_->settings_->endArray ();
  m_->gray_line_duration_ = m_->settings_->value ("GrayLineDuration", 60).toUInt ();
}

WSPRBandHopping::~WSPRBandHopping ()
{
  // save settings
  SettingsGroup g {m_->settings_, title};
  m_->settings_->beginWriteArray ("periods");
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
      m_->dialog_ = new Dialog {m_->settings_, m_->bands_, &m_->gray_line_duration_, m_->parent_widget_};
    }
  m_->dialog_->show ();
  m_->dialog_->resize_to_maximum ();
  m_->dialog_->adjustSize ();   // fix the size
  m_->dialog_->setMinimumSize (m_->dialog_->size ());
  m_->dialog_->setMaximumSize (m_->dialog_->size ());
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

  // look up band for this period
  FC_hopping (&year, &month, &day, &uth, my_grid.toLatin1 ().constData ()
           , &m_->gray_line_duration_, &m_->tx_percent_, &period_index, &band_index
           , &tx_next, my_grid.size ());

  // consult scheduler to determine if next period should be a tx interval
  tx_next = next_tx_state(m_->tx_percent_);

  if (100 == m_->tx_percent_)
    {
      tx_next = 1;
    }

  int frequencies_index {-1};
  auto const& frequencies = m_->configuration_->frequencies ();
  auto const& filtered_bands = frequencies->filtered_bands ();
  if (m_->bands_[period_index].testBit (band_index)
      && filtered_bands.contains (hopping_bands[band_index]))
    {
      // here we have a band that has been enabled in the hopping
      // matrix so check it it has a configured working frequency
      frequencies_index = frequencies->best_working_frequency (hopping_bands[band_index]);
      qDebug () << "scheduled:" << hopping_bands[band_index] << "frequency:" << frequencies->data (frequencies->index (frequencies_index, FrequencyList::frequency_column)).toString ();
    }

  // if we do not have a configured working frequency we next check
  // for a random selection from the other enabled bands in the
  // hopping matrix
  if (frequencies_index < 0)
    {
      for (auto i = 0u; i < num_bands; ++i)
        {
          int new_index = static_cast<int> (qrand () % num_bands); // random choice
          if (new_index != band_index && m_->bands_[period_index].testBit (new_index))
            {
              // here we have a random choice that is enabled in the
              // hopping matrix and not the scheduled choice so we now
              // check if it has a configured working frequency
              frequencies_index = frequencies->best_working_frequency (hopping_bands[new_index]);
              if (frequencies_index >= 0)
                {
                  // we can use the random choice
                  qDebug () << "random:" << hopping_bands[new_index] << "frequency:" << frequencies->data (frequencies->index (frequencies_index, FrequencyList::frequency_column)).toString ();
                  band_index = new_index;
                  break;
                }
            }
        }
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
