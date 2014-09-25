#include "Configuration.hpp"

#include <stdexcept>
#include <iterator>
#include <algorithm>
#include <functional>

#include <QApplication>
#include <QMetaType>
#include <QSettings>
#include <QAudioDeviceInfo>
#include <QAudioInput>
#include <QDialog>
#include <QMessageBox>
#include <QAction>
#include <QFileDialog>
#include <QDir>
#include <QFormLayout>
#include <QString>
#include <QStringList>
#include <QStringListModel>
#include <QLineEdit>
#include <QRegExpValidator>
#include <QThread>
#include <QTimer>
#include <QStandardPaths>
#include <QFont>
#include <QFontDialog>
#include <QDebug>

#include "ui_Configuration.h"

#include "SettingsGroup.hpp"
#include "FrequencyLineEdit.hpp"
#include "FrequencyItemDelegate.hpp"
#include "ForeignKeyDelegate.hpp"
#include "TransceiverFactory.hpp"
#include "Transceiver.hpp"
#include "Bands.hpp"
#include "FrequencyList.hpp"
#include "StationList.hpp"

#include "pimpl_impl.hpp"

#include "moc_Configuration.cpp"

namespace
{
  struct init
  {
    init ()
    {
      qRegisterMetaType<Configuration::DataMode> ("Configuration::DataMode");
      qRegisterMetaTypeStreamOperators<Configuration::DataMode> ("Configuration::DataMode");
    }
  } static_initializer;

  // these undocumented flag values when stored in (Qt::UserRole - 1)
  // of a ComboBox item model index allow the item to be enabled or
  // disabled
  int const combo_box_item_enabled (32 | 1);
  int const combo_box_item_disabled (0);

  QRegExp message_alphabet {"[- A-Za-z0-9+./?]*"};
}


//
// Dialog to get a new Frequency item
//
class FrequencyDialog final
  : public QDialog
{
public:
  using Frequency = Radio::Frequency;

  explicit FrequencyDialog (QWidget * parent = nullptr)
    : QDialog {parent}
  {
    setWindowTitle (QApplication::applicationName () + " - " + tr ("Add Frequency"));

    auto form_layout = new QFormLayout ();
    form_layout->addRow (tr ("&Frequency (MHz):"), &frequency_line_edit_);

    auto main_layout = new QVBoxLayout (this);
    main_layout->addLayout (form_layout);

    auto button_box = new QDialogButtonBox {QDialogButtonBox::Ok | QDialogButtonBox::Cancel};
    main_layout->addWidget (button_box);

    connect (button_box, &QDialogButtonBox::accepted, this, &FrequencyDialog::accept);
    connect (button_box, &QDialogButtonBox::rejected, this, &FrequencyDialog::reject);
  }

  Frequency frequency () const
  {
    return frequency_line_edit_.frequency ();
  }

private:
  FrequencyLineEdit frequency_line_edit_;
};


//
// Dialog to get a new Station item
//
class StationDialog final
  : public QDialog
{
public:
  explicit StationDialog (Bands * bands, QWidget * parent = nullptr)
    : QDialog {parent}
    , bands_ {bands}
  {
    setWindowTitle (QApplication::applicationName () + " - " + tr ("Add Station"));

    band_.setModel (bands_);
      
    auto form_layout = new QFormLayout ();
    form_layout->addRow (tr ("&Band:"), &band_);
    form_layout->addRow (tr ("&Offset (MHz):"), &delta_);
    form_layout->addRow (tr ("&Antenna:"), &description_);

    auto main_layout = new QVBoxLayout (this);
    main_layout->addLayout (form_layout);

    auto button_box = new QDialogButtonBox {QDialogButtonBox::Ok | QDialogButtonBox::Cancel};
    main_layout->addWidget (button_box);

    connect (button_box, &QDialogButtonBox::accepted, this, &StationDialog::accept);
    connect (button_box, &QDialogButtonBox::rejected, this, &StationDialog::reject);

    if (delta_.text ().isEmpty ())
      {
        delta_.setText ("0");
      }
  }

  StationList::Station station () const
  {
    return {band_.currentText (), delta_.frequency_delta (), description_.text ()};
  }

private:
  Bands * bands_;

  QComboBox band_;
  FrequencyDeltaLineEdit delta_;
  QLineEdit description_;
};

class RearrangableMacrosModel
  : public QStringListModel
{
public:
  Qt::ItemFlags flags (QModelIndex const& index) const override
  {
    auto flags = QStringListModel::flags (index);
    if (index.isValid ())
      {
        // disallow drop onto existing items
        flags &= ~Qt::ItemIsDropEnabled;
      }
    return flags;
  }
};


// Class MessageItemDelegate
//
//	Item delegate for message entry such as free text message macros.
//
class MessageItemDelegate final
  : public QStyledItemDelegate
{
public:
  explicit MessageItemDelegate (QObject * parent = nullptr)
    : QStyledItemDelegate {parent}
  {
  }

  QWidget * createEditor (QWidget * parent
                          , QStyleOptionViewItem const& /* option*/
                          , QModelIndex const& /* index */
                          ) const override
  {
    auto editor = new QLineEdit {parent};
    editor->setFrame (false);
    editor->setValidator (new QRegExpValidator {message_alphabet, editor});
    return editor;
  }
};


// Fields that are transceiver related.
//
// These are aggregated in a structure to enable a non-equivalence to
// be provided.
//
// don't forget to update the != operator if any fields are added
// otherwise rig parameter changes will not trigger reconfiguration
struct RigParams
{
  QString CAT_serial_port_;
  QString CAT_network_port_;
  qint32 CAT_baudrate_;
  TransceiverFactory::DataBits CAT_data_bits_;
  TransceiverFactory::StopBits CAT_stop_bits_;
  TransceiverFactory::Handshake CAT_handshake_;
  bool CAT_DTR_always_on_;
  bool CAT_RTS_always_on_;
  qint32 CAT_poll_interval_;
  TransceiverFactory::PTTMethod PTT_method_;
  QString PTT_port_;
  TransceiverFactory::TXAudioSource TX_audio_source_;
  TransceiverFactory::SplitMode split_mode_;
  QString rig_name_;
};
bool operator != (RigParams const&, RigParams const&);

inline
bool operator == (RigParams const& lhs, RigParams const& rhs)
{
  return !(lhs != rhs);
}


// Internal implementation of the Configuration class.
class Configuration::impl final
  : public QDialog
{
  Q_OBJECT;

public:
  using FrequencyDelta = Radio::FrequencyDelta;

  explicit impl (Configuration * self, QString const& instance_key, QSettings * settings, bool test_mode, QWidget * parent);
  ~impl ();

  bool have_rig (bool open_if_closed = true);

  void transceiver_frequency (Frequency);
  void transceiver_tx_frequency (Frequency);
  void transceiver_mode (MODE);
  void transceiver_ptt (bool);
  void sync_transceiver (bool force_signal);

  Q_SLOT int exec () override;
  Q_SLOT void accept () override;
  Q_SLOT void reject () override;
  Q_SLOT void done (int) override;

private:
  typedef QList<QAudioDeviceInfo> AudioDevices;

  void read_settings ();
  void write_settings ();

  bool load_audio_devices (QAudio::Mode, QComboBox *, QAudioDeviceInfo *);
  void update_audio_channels (QComboBox const *, int, QComboBox *, bool);

  void initialise_models ();
  bool open_rig ();
  bool set_mode ();
  void close_rig ();
  void enumerate_rigs ();
  void set_rig_invariants ();
  bool validate ();
  void message_box (QString const& reason, QString const& detail = QString ());
  void fill_port_combo_box (QComboBox *);

  Q_SLOT void on_font_push_button_clicked ();
  Q_SLOT void on_decoded_text_font_push_button_clicked ();

  Q_SLOT void on_PTT_port_combo_box_activated (int);

  Q_SLOT void on_CAT_port_combo_box_activated (int);

  Q_SLOT void on_CAT_serial_baud_combo_box_currentIndexChanged (int);

  Q_SLOT void on_CAT_data_bits_button_group_buttonClicked (int);

  Q_SLOT void on_CAT_stop_bits_button_group_buttonClicked (int);

  Q_SLOT void on_CAT_handshake_button_group_buttonClicked (int);

  Q_SLOT void on_CAT_poll_interval_spin_box_valueChanged (int);

  Q_SLOT void on_split_mode_button_group_buttonClicked (int);

  Q_SLOT void on_test_CAT_push_button_clicked ();

  Q_SLOT void on_test_PTT_push_button_clicked ();

  Q_SLOT void on_CAT_DTR_check_box_toggled (bool);

  Q_SLOT void on_CAT_RTS_check_box_toggled (bool);

  Q_SLOT void on_rig_combo_box_currentIndexChanged (int);

  Q_SLOT void on_sound_input_combo_box_currentTextChanged (QString const&);
  Q_SLOT void on_sound_output_combo_box_currentTextChanged (QString const&);

  Q_SLOT void on_add_macro_push_button_clicked (bool = false);
  Q_SLOT void on_delete_macro_push_button_clicked (bool = false);

  Q_SLOT void on_PTT_method_button_group_buttonClicked (int);

  Q_SLOT void on_callsign_line_edit_editingFinished ();

  Q_SLOT void on_grid_line_edit_editingFinished ();

  Q_SLOT void on_add_macro_line_edit_editingFinished ();
  Q_SLOT void delete_macro ();
  void delete_selected_macros (QModelIndexList);

  Q_SLOT void on_save_path_select_push_button_clicked (bool);

  Q_SLOT void delete_frequencies ();
  Q_SLOT void insert_frequency ();

  Q_SLOT void delete_stations ();
  Q_SLOT void insert_station ();

  Q_SLOT void handle_transceiver_update (TransceiverState);
  Q_SLOT void handle_transceiver_failure (QString reason);

  // typenames used as arguments must match registered type names :(
  Q_SIGNAL void stop_transceiver () const;
  Q_SIGNAL void frequency (Frequency rx) const;
  Q_SIGNAL void tx_frequency (Frequency tx, bool rationalize_mode) const;
  Q_SIGNAL void mode (Transceiver::MODE, bool rationalize) const;
  Q_SIGNAL void ptt (bool) const;
  Q_SIGNAL void sync (bool force_signal) const;

  Configuration * const self_;	// back pointer to public interface

  QThread transceiver_thread_;
  TransceiverFactory transceiver_factory_;

  Ui::configuration_dialog * ui_;

  QSettings * settings_;

  QDir doc_path_;
  QDir temp_path_;
  QDir data_path_;
  QDir default_save_directory_;
  QDir save_directory_;

  QFont font_;
  bool font_changed_;
  QFont next_font_;

  QFont decoded_text_font_;
  bool decoded_text_font_changed_;
  QFont next_decoded_text_font_;

  bool restart_sound_input_device_;
  bool restart_sound_output_device_;

  unsigned jt9w_bw_mult_;
  float jt9w_min_dt_;
  float jt9w_max_dt_;

  QStringListModel macros_;
  RearrangableMacrosModel next_macros_;
  QAction * macro_delete_action_;
  
  Bands bands_;
  FrequencyList frequencies_;
  FrequencyList next_frequencies_;
  StationList stations_;
  StationList next_stations_;

  QAction * frequency_delete_action_;
  QAction * frequency_insert_action_;
  FrequencyDialog * frequency_dialog_;

  QAction * station_delete_action_;
  QAction * station_insert_action_;
  StationDialog * station_dialog_;

  RigParams rig_params_;
  RigParams saved_rig_params_;
  bool rig_active_;
  bool have_rig_;
  bool rig_changed_;
  TransceiverState cached_rig_state_;
  bool ptt_state_;
  bool setup_split_;
  bool enforce_mode_and_split_;
  FrequencyDelta transceiver_offset_;

  // configuration fields that we publish
  QString my_callsign_;
  QString my_grid_;
  qint32 id_interval_;
  bool id_after_73_;
  bool tx_QSY_allowed_;
  bool spot_to_psk_reporter_;
  bool monitor_off_at_startup_;
  bool log_as_RTTY_;
  bool report_in_comments_;
  bool prompt_to_log_;
  bool insert_blank_;
  bool DXCC_;
  bool clear_DX_;
  bool miles_;
  bool quick_call_;
  bool disable_TX_on_73_;
  bool watchdog_;
  bool TX_messages_;
  DataMode data_mode_;

  QAudioDeviceInfo audio_input_device_;
  bool default_audio_input_device_selected_;
  AudioDevice::Channel audio_input_channel_;
  QAudioDeviceInfo audio_output_device_;
  bool default_audio_output_device_selected_;
  AudioDevice::Channel audio_output_channel_;

  friend class Configuration;
};

#include "Configuration.moc"


// delegate to implementation class
Configuration::Configuration (QString const& instance_key, QSettings * settings, bool test_mode, QWidget * parent)
  : m_ {this, instance_key, settings, test_mode, parent}
{
}

Configuration::~Configuration ()
{
}

QDir Configuration::doc_path () const {return m_->doc_path_;}
QDir Configuration::data_path () const {return m_->data_path_;}

int Configuration::exec () {return m_->exec ();}

QAudioDeviceInfo const& Configuration::audio_input_device () const {return m_->audio_input_device_;}
AudioDevice::Channel Configuration::audio_input_channel () const {return m_->audio_input_channel_;}
QAudioDeviceInfo const& Configuration::audio_output_device () const {return m_->audio_output_device_;}
AudioDevice::Channel Configuration::audio_output_channel () const {return m_->audio_output_channel_;}
bool Configuration::restart_audio_input () const {return m_->restart_sound_input_device_;}
bool Configuration::restart_audio_output () const {return m_->restart_sound_output_device_;}
unsigned Configuration::jt9w_bw_mult () const {return m_->jt9w_bw_mult_;}
float Configuration::jt9w_min_dt () const {return m_->jt9w_min_dt_;}
float Configuration::jt9w_max_dt () const {return m_->jt9w_max_dt_;}
QString Configuration::my_callsign () const {return m_->my_callsign_;}
QString Configuration::my_grid () const {return m_->my_grid_;}
QFont Configuration::decoded_text_font () const {return m_->decoded_text_font_;}
qint32 Configuration::id_interval () const {return m_->id_interval_;}
bool Configuration::id_after_73 () const {return m_->id_after_73_;}
bool Configuration::tx_QSY_allowed () const {return m_->tx_QSY_allowed_;}
bool Configuration::spot_to_psk_reporter () const {return m_->spot_to_psk_reporter_;}
bool Configuration::monitor_off_at_startup () const {return m_->monitor_off_at_startup_;}
bool Configuration::log_as_RTTY () const {return m_->log_as_RTTY_;}
bool Configuration::report_in_comments () const {return m_->report_in_comments_;}
bool Configuration::prompt_to_log () const {return m_->prompt_to_log_;}
bool Configuration::insert_blank () const {return m_->insert_blank_;}
bool Configuration::DXCC () const {return m_->DXCC_;}
bool Configuration::clear_DX () const {return m_->clear_DX_;}
bool Configuration::miles () const {return m_->miles_;}
bool Configuration::quick_call () const {return m_->quick_call_;}
bool Configuration::disable_TX_on_73 () const {return m_->disable_TX_on_73_;}
bool Configuration::watchdog () const {return m_->watchdog_;}
bool Configuration::TX_messages () const {return m_->TX_messages_;}
bool Configuration::split_mode () const
{
  bool have_rig = m_->transceiver_factory_.CAT_port_type (m_->rig_params_.rig_name_) != TransceiverFactory::Capabilities::none;
  return have_rig && m_->rig_params_.split_mode_ != TransceiverFactory::split_mode_none;
}
Bands * Configuration::bands () {return &m_->bands_;}
StationList * Configuration::stations () {return &m_->stations_;}
FrequencyList * Configuration::frequencies () {return &m_->frequencies_;}
QStringListModel * Configuration::macros () {return &m_->macros_;}
QDir Configuration::save_directory () const {return m_->save_directory_;}
QString Configuration::rig_name () const {return m_->rig_params_.rig_name_;}

bool Configuration::transceiver_online (bool open_if_closed)
{
#if WSJT_TRACE_CAT
  qDebug () << "Configuration::transceiver_online: open_if_closed:" << open_if_closed << m_->cached_rig_state_;
#endif

  return m_->have_rig (open_if_closed);
}

void Configuration::transceiver_offline ()
{
#if WSJT_TRACE_CAT
  qDebug () << "Configuration::transceiver_offline:" << m_->cached_rig_state_;
#endif

  return m_->close_rig ();
}

void Configuration::transceiver_frequency (Frequency f)
{
#if WSJT_TRACE_CAT
  qDebug () << "Configuration::transceiver_frequency:" << f << m_->cached_rig_state_;
#endif

  m_->transceiver_frequency (f);
}

void Configuration::transceiver_tx_frequency (Frequency f)
{
#if WSJT_TRACE_CAT
  qDebug () << "Configuration::transceiver_tx_frequency:" << f << m_->cached_rig_state_;
#endif

  m_->setup_split_ = true;
  m_->transceiver_tx_frequency (f);
}

void Configuration::transceiver_mode (MODE mode)
{
#if WSJT_TRACE_CAT
  qDebug () << "Configuration::transceiver_mode:" << mode << m_->cached_rig_state_;
#endif

  m_->transceiver_mode (mode);
}

void Configuration::transceiver_ptt (bool on)
{
#if WSJT_TRACE_CAT
  qDebug () << "Configuration::transceiver_ptt:" << on << m_->cached_rig_state_;
#endif

  m_->transceiver_ptt (on);
}

void Configuration::sync_transceiver (bool force_signal, bool enforce_mode_and_split)
{
#if WSJT_TRACE_CAT
  qDebug () << "Configuration::sync_transceiver: force signal:" << force_signal << "enforce_mode_and_split:" << enforce_mode_and_split << m_->cached_rig_state_;
#endif

  m_->enforce_mode_and_split_ = enforce_mode_and_split;
  m_->setup_split_ = enforce_mode_and_split;
  m_->sync_transceiver (force_signal);
}


Configuration::impl::impl (Configuration * self, QString const& instance_key, QSettings * settings, bool test_mode, QWidget * parent)
  : QDialog {parent}
  , self_ {self}
  , ui_ {new Ui::configuration_dialog}
  , settings_ {settings}
  , doc_path_ {QApplication::applicationDirPath ()}
  , temp_path_ {QApplication::applicationDirPath ()}
  , data_path_ {QApplication::applicationDirPath ()}
  , font_ {QApplication::font ()}
  , font_changed_ {false}
  , decoded_text_font_changed_ {false}
  , frequencies_ {
    {
      136130,
        474200,
        1838000,
        3576000,
        5357000,
        7076000,
        10138000,
        14076000,
        18102000,
        21076000,
        24917000,
        28076000,
        50276000,
        70091000,
        144489000,
        }
    }
  , stations_ {&bands_}
  , next_stations_ {&bands_}
  , frequency_dialog_ {new FrequencyDialog {this}}
  , station_dialog_ {new StationDialog {&bands_, this}}
  , rig_active_ {false}
  , have_rig_ {false}
  , rig_changed_ {false}
  , ptt_state_ {false}
  , setup_split_ {false}
  , enforce_mode_and_split_ {false}
  , transceiver_offset_ {0}
  , default_audio_input_device_selected_ {false}
  , default_audio_output_device_selected_ {false}
{
  (void)instance_key;		// quell compiler warning

  ui_->setupUi (this);

  // we must find this before changing the CWD since that breaks
  // QCoreApplication::applicationDirPath() which is used internally
  // by QStandardPaths :(
#if !defined (Q_OS_WIN) || QT_VERSION >= 0x050300
  auto path = QStandardPaths::locate (QStandardPaths::DataLocation, WSJT_DOC_DESTINATION, QStandardPaths::LocateDirectory);
  if (path.isEmpty ())
    {
      doc_path_.cdUp ();
#if defined (Q_OS_MAC)
      doc_path_.cdUp ();
      doc_path_.cdUp ();
#endif
      doc_path_.cd (WSJT_SHARE_DESTINATION);
      doc_path_.cd (WSJT_DOC_DESTINATION);
    }
  else
    {
      doc_path_.cd (path);
    }
#else
  doc_path_.cd (WSJT_DOC_DESTINATION);
#endif

#if WSJT_STANDARD_FILE_LOCATIONS
  // the following needs to be done on all platforms but changes need
  // coordination with JTAlert developers
  {
    // Create a temporary directory in a suitable location
    QString temp_location {QStandardPaths::writableLocation (QStandardPaths::TempLocation)};
    if (!temp_location.isEmpty ())
      {
        temp_path_.setPath (temp_location);
      }

    QString unique_directory {instance_key};
    if (test_mode)
      {
        unique_directory += " - test_mode";
      }
    if (!temp_path_.mkpath (unique_directory) || !temp_path_.cd (unique_directory))
      {
        QMessageBox::critical (this, "WSJT-X", tr ("Create temporary directory error: ") + temp_path_.absolutePath ());
        throw std::runtime_error {"Failed to create usable temporary directory"};
      }
  }

  // kvasd writes files to $cwd so by changing to the temp directory
  // we can keep these files out of the startup directory
  QDir::setCurrent (temp_path_.absolutePath ());
  
  // we run kvasd with a $cwd of our temp directory so we need to copy
  // in a fresh kvasd.dat for it
  //
  // this requirement changes with kvasd v 1.12 since it has a
  // parameter to set the data file path
  QString kvasd_data_file {"kvasd.dat"};
  if (!temp_path_.exists (kvasd_data_file))
    {
      auto dest_file = temp_path_.absoluteFilePath (kvasd_data_file);
      if (!QFile::copy (":/" + kvasd_data_file, dest_file))
        {
          QMessageBox::critical (this, "WSJT-X", tr ("Cannot copy: :/") + kvasd_data_file + tr (" to: ") + temp_path_.absolutePath ());
          throw std::runtime_error {"Failed to copy kvasd.dat to temporary directory"};
        }
      else
        {
          QFile {dest_file}.setPermissions (QFile::ReadOwner | QFile::WriteOwner);
        }
    }


  {
    // Find a suitable data file location
    QString data_location {QStandardPaths::writableLocation (QStandardPaths::DataLocation)};
    if (!data_location.isEmpty ())
      {
        data_path_.setPath (data_location);
      }

    if (!data_path_.mkpath ("."))
      {
        QMessageBox::critical (this, "WSJT-X", tr ("Create data directory error: ") + data_path_.absolutePath ());
        throw std::runtime_error {"Failed to create data directory"};
      }
  }
  // qDebug () << "Data store path:" << data_path_.absolutePath ();
  // auto paths = QStandardPaths::standardLocations (QStandardPaths::DataLocation);
  // Q_FOREACH (auto const& path, paths)
  //   {
  //     qDebug () << "path:" << path;
  //   }
#endif

  {
    // Make sure the default save directory exists
    QString save_dir {"save"};
    default_save_directory_ = data_path_;
    if (!default_save_directory_.mkpath (save_dir) || !default_save_directory_.cd (save_dir))
      {
        QMessageBox::critical (this, "WSJT-X", tr ("Create Directory", "Cannot create directory \"") + default_save_directory_.absoluteFilePath (save_dir) + "\".");
        throw std::runtime_error {"Failed to create save directory"};
      }

    // we now have a deafult save path that exists

    // make sure samples directory exists
    QString samples_dir {"samples"};
    if (!default_save_directory_.mkpath (samples_dir))
      {
        QMessageBox::critical (this, "WSJT-X", tr ("Create Directory", "Cannot create directory \"") + default_save_directory_.absoluteFilePath (samples_dir) + "\".");
        throw std::runtime_error {"Failed to create save directory"};
      }

    // copy in any new sample files to the sample directory
    QDir dest_dir {default_save_directory_};
    dest_dir.cd (samples_dir);
    
    QDir source_dir {":/" + samples_dir};
    source_dir.cd (save_dir);
    source_dir.cd (samples_dir);
    auto list = source_dir.entryInfoList (QStringList {{"*.wav"}}, QDir::Files | QDir::Readable);
    Q_FOREACH (auto const& item, list)
      {
        if (!dest_dir.exists (item.fileName ()))
          {
            QFile file {item.absoluteFilePath ()};
            file.copy (dest_dir.absoluteFilePath (item.fileName ()));
          }
      }
  }

  // this must be done after the default paths above are set
  read_settings ();

  //
  // validation
  //
  ui_->callsign_line_edit->setValidator (new QRegExpValidator {QRegExp {"[A-Za-z0-9/]+"}, this});
  ui_->grid_line_edit->setValidator (new QRegExpValidator {QRegExp {"[A-Ra-r]{2,2}[0-9]{2,2}[A-Xa-x]{0,2}"}, this});
  ui_->add_macro_line_edit->setValidator (new QRegExpValidator {message_alphabet, this});

  //
  // assign ids to radio buttons
  //
  ui_->CAT_data_bits_button_group->setId (ui_->CAT_7_bit_radio_button, TransceiverFactory::seven_data_bits);
  ui_->CAT_data_bits_button_group->setId (ui_->CAT_8_bit_radio_button, TransceiverFactory::eight_data_bits);

  ui_->CAT_stop_bits_button_group->setId (ui_->CAT_one_stop_bit_radio_button, TransceiverFactory::one_stop_bit);
  ui_->CAT_stop_bits_button_group->setId (ui_->CAT_two_stop_bit_radio_button, TransceiverFactory::two_stop_bits);

  ui_->CAT_handshake_button_group->setId (ui_->CAT_handshake_none_radio_button, TransceiverFactory::handshake_none);
  ui_->CAT_handshake_button_group->setId (ui_->CAT_handshake_xon_radio_button, TransceiverFactory::handshake_XonXoff);
  ui_->CAT_handshake_button_group->setId (ui_->CAT_handshake_hardware_radio_button, TransceiverFactory::handshake_hardware);

  ui_->PTT_method_button_group->setId (ui_->PTT_VOX_radio_button, TransceiverFactory::PTT_method_VOX);
  ui_->PTT_method_button_group->setId (ui_->PTT_CAT_radio_button, TransceiverFactory::PTT_method_CAT);
  ui_->PTT_method_button_group->setId (ui_->PTT_DTR_radio_button, TransceiverFactory::PTT_method_DTR);
  ui_->PTT_method_button_group->setId (ui_->PTT_RTS_radio_button, TransceiverFactory::PTT_method_RTS);

  ui_->TX_audio_source_button_group->setId (ui_->TX_source_mic_radio_button, TransceiverFactory::TX_audio_source_front);
  ui_->TX_audio_source_button_group->setId (ui_->TX_source_data_radio_button, TransceiverFactory::TX_audio_source_rear);

  ui_->TX_mode_button_group->setId (ui_->mode_none_radio_button, data_mode_none);
  ui_->TX_mode_button_group->setId (ui_->mode_USB_radio_button, data_mode_USB);
  ui_->TX_mode_button_group->setId (ui_->mode_data_radio_button, data_mode_data);

  ui_->split_mode_button_group->setId (ui_->split_none_radio_button, TransceiverFactory::split_mode_none);
  ui_->split_mode_button_group->setId (ui_->split_rig_radio_button, TransceiverFactory::split_mode_rig);
  ui_->split_mode_button_group->setId (ui_->split_emulate_radio_button, TransceiverFactory::split_mode_emulate);

  //
  // setup PTT port combo box drop down content
  //
  fill_port_combo_box (ui_->PTT_port_combo_box);
  ui_->PTT_port_combo_box->addItem ("CAT");

  //
  // setup hooks to keep audio channels aligned with devices
  //
  {
    using namespace std;
    using namespace std::placeholders;

    function<void (int)> cb (bind (&Configuration::impl::update_audio_channels, this, ui_->sound_input_combo_box, _1, ui_->sound_input_channel_combo_box, false));
    connect (ui_->sound_input_combo_box, static_cast<void (QComboBox::*)(int)> (&QComboBox::currentIndexChanged), cb);
    cb = bind (&Configuration::impl::update_audio_channels, this, ui_->sound_output_combo_box, _1, ui_->sound_output_channel_combo_box, true);
    connect (ui_->sound_output_combo_box, static_cast<void (QComboBox::*)(int)> (&QComboBox::currentIndexChanged), cb);
  }

  //
  // setup macros list view
  //
  ui_->macros_list_view->setModel (&next_macros_);
  ui_->macros_list_view->setItemDelegate (new MessageItemDelegate {this});

  macro_delete_action_ = new QAction {tr ("&Delete"), ui_->macros_list_view};
  ui_->macros_list_view->insertAction (nullptr, macro_delete_action_);
  connect (macro_delete_action_, &QAction::triggered, this, &Configuration::impl::delete_macro);


  //
  // setup working frequencies table model & view
  //
  frequencies_.sort (0);

  ui_->frequencies_table_view->setModel (&next_frequencies_);
  ui_->frequencies_table_view->sortByColumn (0, Qt::AscendingOrder);
  ui_->frequencies_table_view->setItemDelegateForColumn (0, new FrequencyItemDelegate {&bands_, this});
  ui_->frequencies_table_view->setColumnHidden (1, true);

  frequency_delete_action_ = new QAction {tr ("&Delete"), ui_->frequencies_table_view};
  ui_->frequencies_table_view->insertAction (nullptr, frequency_delete_action_);
  connect (frequency_delete_action_, &QAction::triggered, this, &Configuration::impl::delete_frequencies);

  frequency_insert_action_ = new QAction {tr ("&Insert ..."), ui_->frequencies_table_view};
  ui_->frequencies_table_view->insertAction (nullptr, frequency_insert_action_);
  connect (frequency_insert_action_, &QAction::triggered, this, &Configuration::impl::insert_frequency);


  //
  // setup stations table model & view
  //
  stations_.sort (0);

  ui_->stations_table_view->setModel (&next_stations_);
  ui_->stations_table_view->sortByColumn (0, Qt::AscendingOrder);
  ui_->stations_table_view->setColumnWidth (1, 150);
  ui_->stations_table_view->setItemDelegateForColumn (0, new ForeignKeyDelegate {&next_stations_, &bands_, 0, this});
  ui_->stations_table_view->setItemDelegateForColumn (1, new FrequencyDeltaItemDelegate {this});

  station_delete_action_ = new QAction {tr ("&Delete"), ui_->stations_table_view};
  ui_->stations_table_view->insertAction (nullptr, station_delete_action_);
  connect (station_delete_action_, &QAction::triggered, this, &Configuration::impl::delete_stations);

  station_insert_action_ = new QAction {tr ("&Insert ..."), ui_->stations_table_view};
  ui_->stations_table_view->insertAction (nullptr, station_insert_action_);
  connect (station_insert_action_, &QAction::triggered, this, &Configuration::impl::insert_station);

  //
  // load combo boxes with audio setup choices
  //
  default_audio_input_device_selected_ = load_audio_devices (QAudio::AudioInput, ui_->sound_input_combo_box, &audio_input_device_);
  default_audio_output_device_selected_ = load_audio_devices (QAudio::AudioOutput, ui_->sound_output_combo_box, &audio_output_device_);

  update_audio_channels (ui_->sound_input_combo_box, ui_->sound_input_combo_box->currentIndex (), ui_->sound_input_channel_combo_box, false);
  update_audio_channels (ui_->sound_output_combo_box, ui_->sound_output_combo_box->currentIndex (), ui_->sound_output_channel_combo_box, true);

  ui_->sound_input_channel_combo_box->setCurrentIndex (audio_input_channel_);
  ui_->sound_output_channel_combo_box->setCurrentIndex (audio_output_channel_);

  restart_sound_input_device_ = false;
  restart_sound_output_device_ = false;

  enumerate_rigs ();
  initialise_models ();

  transceiver_thread_.start ();

#if !WSJT_ENABLE_EXPERIMENTAL_FEATURES
  ui_->jt9w_group_box->setEnabled (false);
#endif
}

Configuration::impl::~impl ()
{
  write_settings ();

  close_rig ();

  transceiver_thread_.quit ();
  transceiver_thread_.wait ();

  QDir::setCurrent (QApplication::applicationDirPath ());
#if WSJT_STANDARD_FILE_LOCATIONS
  temp_path_.removeRecursively (); // clean up temp files
#endif
}

void Configuration::impl::initialise_models ()
{
  auto pal = ui_->callsign_line_edit->palette ();
  if (my_callsign_.isEmpty ())
    {
      pal.setColor (QPalette::Base, "#ffccff");
    }
  else
    {
      pal.setColor (QPalette::Base, Qt::white);
    }
  ui_->callsign_line_edit->setPalette (pal);
  ui_->grid_line_edit->setPalette (pal);
  ui_->callsign_line_edit->setText (my_callsign_);
  ui_->grid_line_edit->setText (my_grid_);
  font_changed_ = false;
  decoded_text_font_changed_ = false;
  ui_->CW_id_interval_spin_box->setValue (id_interval_);
  ui_->PTT_method_button_group->button (rig_params_.PTT_method_)->setChecked (true);
  ui_->save_path_display_label->setText (save_directory_.absolutePath ());
  ui_->CW_id_after_73_check_box->setChecked (id_after_73_);
  ui_->tx_QSY_check_box->setChecked (tx_QSY_allowed_);
  ui_->psk_reporter_check_box->setChecked (spot_to_psk_reporter_);
  ui_->monitor_off_check_box->setChecked (monitor_off_at_startup_);
  ui_->log_as_RTTY_check_box->setChecked (log_as_RTTY_);
  ui_->report_in_comments_check_box->setChecked (report_in_comments_);
  ui_->prompt_to_log_check_box->setChecked (prompt_to_log_);
  ui_->insert_blank_check_box->setChecked (insert_blank_);
  ui_->DXCC_check_box->setChecked (DXCC_);
  ui_->clear_DX_check_box->setChecked (clear_DX_);
  ui_->miles_check_box->setChecked (miles_);
  ui_->quick_call_check_box->setChecked (quick_call_);
  ui_->disable_TX_on_73_check_box->setChecked (disable_TX_on_73_);
  ui_->watchdog_check_box->setChecked (watchdog_);
  ui_->TX_messages_check_box->setChecked (TX_messages_);
  ui_->jt9w_bandwidth_mult_combo_box->setCurrentText (QString::number (jt9w_bw_mult_));
  ui_->jt9w_min_dt_double_spin_box->setValue (jt9w_min_dt_);
  ui_->jt9w_max_dt_double_spin_box->setValue (jt9w_max_dt_);
  ui_->rig_combo_box->setCurrentText (rig_params_.rig_name_);
  ui_->TX_mode_button_group->button (data_mode_)->setChecked (true);
  ui_->split_mode_button_group->button (rig_params_.split_mode_)->setChecked (true);
  ui_->CAT_serial_baud_combo_box->setCurrentText (QString::number (rig_params_.CAT_baudrate_));
  ui_->CAT_data_bits_button_group->button (rig_params_.CAT_data_bits_)->setChecked (true);
  ui_->CAT_stop_bits_button_group->button (rig_params_.CAT_stop_bits_)->setChecked (true);
  ui_->CAT_handshake_button_group->button (rig_params_.CAT_handshake_)->setChecked (true);
  ui_->CAT_DTR_check_box->setChecked (rig_params_.CAT_DTR_always_on_);
  ui_->CAT_RTS_check_box->setChecked (rig_params_.CAT_RTS_always_on_);
  ui_->TX_audio_source_button_group->button (rig_params_.TX_audio_source_)->setChecked (true);
  ui_->CAT_poll_interval_spin_box->setValue (rig_params_.CAT_poll_interval_);

  if (rig_params_.PTT_port_.isEmpty ())
    {
      if (ui_->PTT_port_combo_box->count ())
        {
          ui_->PTT_port_combo_box->setCurrentText (ui_->PTT_port_combo_box->itemText (0));
        }
    }
  else
    {
      ui_->PTT_port_combo_box->setCurrentText (rig_params_.PTT_port_);
    }

  next_macros_.setStringList (macros_.stringList ());
  next_frequencies_ = frequencies_.frequencies ();
  next_stations_ = stations_.stations ();

  set_rig_invariants ();
}

void Configuration::impl::done (int r)
{
  // do this here since window is still on screen at this point
  SettingsGroup g {settings_, "Configuration"};
  settings_->setValue ("window/size", size ());
  settings_->setValue ("window/pos", pos ());

  QDialog::done (r);
}

void Configuration::impl::read_settings ()
{
  SettingsGroup g {settings_, "Configuration"};

  resize (settings_->value ("window/size", size ()).toSize ());
  move (settings_->value ("window/pos", pos ()).toPoint ());

  my_callsign_ = settings_->value ("MyCall", "").toString ();
  my_grid_ = settings_->value ("MyGrid", "").toString ();

  if (next_font_.fromString (settings_->value ("Font", QGuiApplication::font ().toString ()).toString ())
      && next_font_ != QGuiApplication::font ())
    {
      font_ = next_font_;
      QApplication::setFont (font_);
    }

  if (next_decoded_text_font_.fromString (settings_->value ("DecodedTextFont", "Courier, 10").toString ())
      && decoded_text_font_ != next_decoded_text_font_)
    {
      decoded_text_font_ = next_decoded_text_font_;
      Q_EMIT self_->decoded_text_font_changed (decoded_text_font_);
    }

  id_interval_ = settings_->value ("IDint", 0).toInt ();

  save_directory_ = settings_->value ("SaveDir", default_save_directory_.absolutePath ()).toString ();

  {
    //
    // retrieve audio input device
    //
    auto saved_name = settings_->value ("SoundInName").toString ();

    // deal with special Windows default audio devices
    auto default_device = QAudioDeviceInfo::defaultInputDevice ();
    if (saved_name == default_device.deviceName ())
      {
        audio_input_device_ = default_device;
        default_audio_input_device_selected_ = true;
      }
    else
      {
        default_audio_input_device_selected_ = false;
        Q_FOREACH (auto const& p, QAudioDeviceInfo::availableDevices (QAudio::AudioInput)) // available audio input devices
          {
            if (p.deviceName () == saved_name)
              {
                audio_input_device_ = p;
              }
          }
      }
  }

  {
    //
    // retrieve audio output device
    //
    auto saved_name = settings_->value("SoundOutName").toString();

    // deal with special Windows default audio devices
    auto default_device = QAudioDeviceInfo::defaultOutputDevice ();
    if (saved_name == default_device.deviceName ())
      {
        audio_output_device_ = default_device;
        default_audio_output_device_selected_ = true;
      }
    else
      {
        default_audio_output_device_selected_ = false;
        Q_FOREACH (auto const& p, QAudioDeviceInfo::availableDevices (QAudio::AudioOutput)) // available audio output devices
          {
            if (p.deviceName () == saved_name)
              {
                audio_output_device_ = p;
              }
          }
      }
  }

  // retrieve audio channel info
  audio_input_channel_ = AudioDevice::fromString (settings_->value ("AudioInputChannel", "Mono").toString ());
  audio_output_channel_ = AudioDevice::fromString (settings_->value ("AudioOutputChannel", "Mono").toString ());

  jt9w_bw_mult_ = settings_->value ("ToneMult", 1).toUInt ();
  jt9w_min_dt_ = settings_->value ("DTmin", -2.5).toFloat ();
  jt9w_max_dt_ = settings_->value ("DTmax", 5.).toFloat ();

  monitor_off_at_startup_ = settings_->value ("MonitorOFF", false).toBool ();
  spot_to_psk_reporter_ = settings_->value ("PSKReporter", false).toBool ();
  id_after_73_ = settings_->value ("After73", false).toBool ();
  tx_QSY_allowed_ = settings_->value ("TxQSYAllowed", false).toBool ();

  macros_.setStringList (settings_->value ("Macros", QStringList {"TNX 73 GL"}).toStringList ());

  if (settings_->contains ("frequencies"))
    {
      frequencies_ = settings_->value ("frequencies").value<Radio::Frequencies> ();
    }

  stations_ = settings_->value ("stations").value<StationList::Stations> ();

  log_as_RTTY_ = settings_->value ("toRTTY", false).toBool ();
  report_in_comments_ = settings_->value("dBtoComments", false).toBool ();
  rig_params_.rig_name_ = settings_->value ("Rig", TransceiverFactory::basic_transceiver_name_).toString ();
  rig_params_.CAT_network_port_ = settings_->value ("CATNetworkPort").toString ();
  rig_params_.CAT_serial_port_ = settings_->value ("CATSerialPort").toString ();
  rig_params_.CAT_baudrate_ = settings_->value ("CATSerialRate", 4800).toInt ();
  rig_params_.CAT_data_bits_ = settings_->value ("CATDataBits", QVariant::fromValue (TransceiverFactory::eight_data_bits)).value<TransceiverFactory::DataBits> ();
  rig_params_.CAT_stop_bits_ = settings_->value ("CATStopBits", QVariant::fromValue (TransceiverFactory::two_stop_bits)).value<TransceiverFactory::StopBits> ();
  rig_params_.CAT_handshake_ = settings_->value ("CATHandshake", QVariant::fromValue (TransceiverFactory::handshake_none)).value<TransceiverFactory::Handshake> ();
  rig_params_.CAT_DTR_always_on_ = settings_->value ("DTR", false).toBool ();
  rig_params_.CAT_RTS_always_on_ = settings_->value ("RTS", false).toBool ();
  rig_params_.PTT_method_ = settings_->value ("PTTMethod", QVariant::fromValue (TransceiverFactory::PTT_method_VOX)).value<TransceiverFactory::PTTMethod> ();
  rig_params_.TX_audio_source_ = settings_->value ("TXAudioSource", QVariant::fromValue (TransceiverFactory::TX_audio_source_front)).value<TransceiverFactory::TXAudioSource> ();
  rig_params_.PTT_port_ = settings_->value ("PTTport").toString ();
  data_mode_ = settings_->value ("DataMode", QVariant::fromValue (data_mode_none)).value<Configuration::DataMode> ();
  prompt_to_log_ = settings_->value ("PromptToLog", false).toBool ();
  insert_blank_ = settings_->value ("InsertBlank", false).toBool ();
  DXCC_ = settings_->value ("DXCCEntity", false).toBool ();
  clear_DX_ = settings_->value ("ClearCallGrid", false).toBool ();
  miles_ = settings_->value ("Miles", false).toBool ();
  quick_call_ = settings_->value ("QuickCall", false).toBool ();
  disable_TX_on_73_ = settings_->value ("73TxDisable", false).toBool ();
  watchdog_ = settings_->value ("Runaway", false).toBool ();
  TX_messages_ = settings_->value ("Tx2QSO", false).toBool ();
  rig_params_.CAT_poll_interval_ = settings_->value ("Polling", 0).toInt ();
  rig_params_.split_mode_ = settings_->value ("SplitMode", QVariant::fromValue (TransceiverFactory::split_mode_none)).value<TransceiverFactory::SplitMode> ();
}

void Configuration::impl::write_settings ()
{
  SettingsGroup g {settings_, "Configuration"};

  settings_->setValue ("MyCall", my_callsign_);
  settings_->setValue ("MyGrid", my_grid_);

  settings_->setValue ("Font", font_.toString ());
  settings_->setValue ("DecodedTextFont", decoded_text_font_.toString ());

  settings_->setValue ("IDint", id_interval_);

  settings_->setValue ("PTTMethod", QVariant::fromValue (rig_params_.PTT_method_));
  settings_->setValue ("PTTport", rig_params_.PTT_port_);
  settings_->setValue ("SaveDir", save_directory_.absolutePath ());

  if (default_audio_input_device_selected_)
    {
      settings_->setValue ("SoundInName", QAudioDeviceInfo::defaultInputDevice ().deviceName ());
    }
  else
    {
      settings_->setValue ("SoundInName", audio_input_device_.deviceName ());
    }

  if (default_audio_output_device_selected_)
    {
      settings_->setValue ("SoundOutName", QAudioDeviceInfo::defaultOutputDevice ().deviceName ());
    }
  else
    {
      settings_->setValue ("SoundOutName", audio_output_device_.deviceName ());
    }

  settings_->setValue ("AudioInputChannel", AudioDevice::toString (audio_input_channel_));
  settings_->setValue ("AudioOutputChannel", AudioDevice::toString (audio_output_channel_));
  settings_->setValue ("ToneMult", jt9w_bw_mult_);
  settings_->setValue ("DTmin", jt9w_min_dt_);
  settings_->setValue ("DTmax", jt9w_max_dt_);
  settings_->setValue ("MonitorOFF", monitor_off_at_startup_);
  settings_->setValue ("PSKReporter", spot_to_psk_reporter_);
  settings_->setValue ("After73", id_after_73_);
  settings_->setValue ("TxQSYAllowed", tx_QSY_allowed_);
  settings_->setValue ("Macros", macros_.stringList ());
  settings_->setValue ("frequencies", QVariant::fromValue (frequencies_.frequencies ()));
  settings_->setValue ("stations", QVariant::fromValue (stations_.stations ()));
  settings_->setValue ("toRTTY", log_as_RTTY_);
  settings_->setValue ("dBtoComments", report_in_comments_);
  settings_->setValue ("Rig", rig_params_.rig_name_);
  settings_->setValue ("CATNetworkPort", rig_params_.CAT_network_port_);
  settings_->setValue ("CATSerialPort", rig_params_.CAT_serial_port_);
  settings_->setValue ("CATSerialRate", rig_params_.CAT_baudrate_);
  settings_->setValue ("CATDataBits", QVariant::fromValue (rig_params_.CAT_data_bits_));
  settings_->setValue ("CATStopBits", QVariant::fromValue (rig_params_.CAT_stop_bits_));
  settings_->setValue ("CATHandshake", QVariant::fromValue (rig_params_.CAT_handshake_));
  settings_->setValue ("DataMode", QVariant::fromValue (data_mode_));
  settings_->setValue ("PromptToLog", prompt_to_log_);
  settings_->setValue ("InsertBlank", insert_blank_);
  settings_->setValue ("DXCCEntity", DXCC_);
  settings_->setValue ("ClearCallGrid", clear_DX_);
  settings_->setValue ("Miles", miles_);
  settings_->setValue ("QuickCall", quick_call_);
  settings_->setValue ("73TxDisable", disable_TX_on_73_);
  settings_->setValue ("Runaway", watchdog_);
  settings_->setValue ("Tx2QSO", TX_messages_);
  settings_->setValue ("DTR", rig_params_.CAT_DTR_always_on_);
  settings_->setValue ("RTS", rig_params_.CAT_RTS_always_on_);
  settings_->setValue ("TXAudioSource", QVariant::fromValue (rig_params_.TX_audio_source_));
  settings_->setValue ("Polling", rig_params_.CAT_poll_interval_);
  settings_->setValue ("SplitMode", QVariant::fromValue (rig_params_.split_mode_));
}

void Configuration::impl::set_rig_invariants ()
{
  auto const& rig = ui_->rig_combo_box->currentText ();
  auto const& ptt_port = ui_->PTT_port_combo_box->currentText ();
  auto ptt_method = static_cast<TransceiverFactory::PTTMethod> (ui_->PTT_method_button_group->checkedId ());

  auto CAT_PTT_enabled = transceiver_factory_.has_CAT_PTT (rig);
  auto CAT_indirect_serial_PTT = transceiver_factory_.has_CAT_indirect_serial_PTT (rig);
  auto asynchronous_CAT = transceiver_factory_.has_asynchronous_CAT (rig);

  ui_->test_CAT_push_button->setStyleSheet ({});

  ui_->CAT_poll_interval_label->setEnabled (!asynchronous_CAT);
  ui_->CAT_poll_interval_spin_box->setEnabled (!asynchronous_CAT);

  static TransceiverFactory::Capabilities::PortType last_port_type = TransceiverFactory::Capabilities::none;
  auto port_type = transceiver_factory_.CAT_port_type (rig);

  bool is_serial_CAT (TransceiverFactory::Capabilities::serial == port_type);

  if (port_type != last_port_type)
    {
      last_port_type = port_type;

      switch (port_type)
        {
        case TransceiverFactory::Capabilities::serial:
          fill_port_combo_box (ui_->CAT_port_combo_box);
          ui_->CAT_port_combo_box->setCurrentText (rig_params_.CAT_serial_port_);
          if (ui_->CAT_port_combo_box->currentText ().isEmpty () && ui_->CAT_port_combo_box->count ())
            {
              ui_->CAT_port_combo_box->setCurrentText (ui_->CAT_port_combo_box->itemText (0));
            }
  
          ui_->CAT_control_group_box->setEnabled (true);
          ui_->CAT_port_label->setText (tr ("Serial Port:"));
          ui_->CAT_port_combo_box->setToolTip (tr ("Serial port used for CAT control"));
          break;

        case TransceiverFactory::Capabilities::network:
          ui_->CAT_port_combo_box->setCurrentText (rig_params_.CAT_network_port_);

          ui_->CAT_control_group_box->setEnabled (true);
          ui_->CAT_port_label->setText (tr ("Network Server:"));
          ui_->CAT_port_combo_box->setToolTip (tr ("Optional hostname and port of network service.\n"
                                                   "Leave blank for a sensible default on this machine.\n"
                                                   "Formats:\n"
                                                   "\thostname:port\n"
                                                   "\tIPv4-address:port\n"
                                                   "\t[IPv6-address]:port"));
          break;

        default:
          ui_->CAT_port_combo_box->clear ();
          ui_->CAT_control_group_box->setEnabled (false);
          break;
        }
    }

  auto const& cat_port = ui_->CAT_port_combo_box->currentText ();

  ui_->CAT_serial_port_parameters_group_box->setEnabled (is_serial_CAT);

  auto is_hw_handshake = TransceiverFactory::handshake_hardware == static_cast<TransceiverFactory::Handshake> (ui_->CAT_handshake_button_group->checkedId ());
  ui_->CAT_RTS_check_box->setEnabled (is_serial_CAT && !is_hw_handshake);

  ui_->TX_audio_source_group_box->setEnabled (transceiver_factory_.has_CAT_PTT_mic_data (rig) && TransceiverFactory::PTT_method_CAT == ptt_method);

  // if (ui_->test_PTT_push_button->isEnabled ()) // don't enable if disabled - "Test CAT" must succeed first
  //   {
  //     ui_->test_PTT_push_button->setEnabled ((TransceiverFactory::PTT_method_CAT == ptt_method && CAT_PTT_enabled)
  //  					     || TransceiverFactory::PTT_method_DTR == ptt_method
  //  					     || TransceiverFactory::PTT_method_RTS == ptt_method);
  //   }
  ui_->test_PTT_push_button->setEnabled (false);
  
  // only enable CAT option if transceiver has CAT PTT
  ui_->PTT_CAT_radio_button->setEnabled (CAT_PTT_enabled);
  
  auto enable_ptt_port = TransceiverFactory::PTT_method_CAT != ptt_method && TransceiverFactory::PTT_method_VOX != ptt_method;
  ui_->PTT_port_combo_box->setEnabled (enable_ptt_port);
  ui_->PTT_port_label->setEnabled (enable_ptt_port);

  ui_->PTT_port_combo_box->setItemData (ui_->PTT_port_combo_box->findText ("CAT")
                                        , CAT_indirect_serial_PTT ? combo_box_item_enabled : combo_box_item_disabled
                                        , Qt::UserRole - 1);

  ui_->PTT_DTR_radio_button->setEnabled (!(ui_->CAT_DTR_check_box->isChecked ()
                                           && ((is_serial_CAT && ptt_port == cat_port)
                                               || ("CAT" == ptt_port && !CAT_indirect_serial_PTT))));

  ui_->PTT_RTS_radio_button->setEnabled (!((ui_->CAT_RTS_check_box->isChecked () || is_hw_handshake)
                                           && ((ptt_port == cat_port && is_serial_CAT)
                                               || ("CAT" == ptt_port && !CAT_indirect_serial_PTT))));
}

bool Configuration::impl::validate ()
{
  if (ui_->sound_input_combo_box->currentIndex () < 0
      && !QAudioDeviceInfo::availableDevices (QAudio::AudioInput).empty ())
    {
      message_box (tr ("Invalid audio input device"));
      return false;
    }

  if (ui_->sound_output_combo_box->currentIndex () < 0
      && !QAudioDeviceInfo::availableDevices (QAudio::AudioOutput).empty ())
    {
      message_box (tr ("Invalid audio output device"));
      return false;
    }

  if (!ui_->PTT_method_button_group->checkedButton ()->isEnabled ())
    {
      message_box (tr ("Invalid PTT method"));
      return false;
    }

  // auto CAT_port = ui_->CAT_port_combo_box->currentText ();
  // if (ui_->CAT_port_combo_box->isEnabled () && CAT_port.isEmpty ())
  //   {
  //     message_box (tr ("Invalid CAT port"));
  //     return false;
  //   }

  auto ptt_method = static_cast<TransceiverFactory::PTTMethod> (ui_->PTT_method_button_group->checkedId ());
  auto ptt_port = ui_->PTT_port_combo_box->currentText ();
  if ((TransceiverFactory::PTT_method_DTR == ptt_method || TransceiverFactory::PTT_method_RTS == ptt_method)
      && (ptt_port.isEmpty ()
          || combo_box_item_disabled == ui_->PTT_port_combo_box->itemData (ui_->PTT_port_combo_box->findText (ptt_port), Qt::UserRole - 1)))
    {
      message_box (tr ("Invalid PTT port"));
      return false;
    }

  return true;
}

int Configuration::impl::exec ()
{
  // macros can be modified in the main window
  next_macros_.setStringList (macros_.stringList ());

  ptt_state_ = false;
  have_rig_ = rig_active_;	// record that we started with a rig open

  saved_rig_params_ = rig_params_; // used to detect changes that
  // require the Transceiver to be
  // re-opened
  rig_changed_ = false;

  return QDialog::exec();
}

void Configuration::impl::accept ()
{
  // Called when OK button is clicked.

  if (!validate ())
    {
      return;			// not accepting
    }

  // extract all rig related configuration parameters into temporary
  // structure for checking if the rig needs re-opening without
  // actually updating our live state
  RigParams temp_rig_params;
  temp_rig_params.rig_name_ = ui_->rig_combo_box->currentText ();

  switch (transceiver_factory_.CAT_port_type (temp_rig_params.rig_name_))
    {
    case TransceiverFactory::Capabilities::serial:
      temp_rig_params.CAT_serial_port_ = ui_->CAT_port_combo_box->currentText ();
      temp_rig_params.CAT_network_port_ = rig_params_.CAT_network_port_;
      break;

    case TransceiverFactory::Capabilities::network:
      temp_rig_params.CAT_network_port_ = ui_->CAT_port_combo_box->currentText ();
      temp_rig_params.CAT_serial_port_ = rig_params_.CAT_serial_port_;
      break;

    default:
      temp_rig_params.CAT_serial_port_ = rig_params_.CAT_serial_port_;
      temp_rig_params.CAT_network_port_ = rig_params_.CAT_network_port_;
      break;
    }

  temp_rig_params.CAT_baudrate_ = ui_->CAT_serial_baud_combo_box->currentText ().toInt ();
  temp_rig_params.CAT_data_bits_ = static_cast<TransceiverFactory::DataBits> (ui_->CAT_data_bits_button_group->checkedId ());
  temp_rig_params.CAT_stop_bits_ = static_cast<TransceiverFactory::StopBits> (ui_->CAT_stop_bits_button_group->checkedId ());
  temp_rig_params.CAT_handshake_ = static_cast<TransceiverFactory::Handshake> (ui_->CAT_handshake_button_group->checkedId ());
  temp_rig_params.CAT_DTR_always_on_ = ui_->CAT_DTR_check_box->isChecked ();
  temp_rig_params.CAT_RTS_always_on_ = ui_->CAT_RTS_check_box->isChecked ();
  temp_rig_params.CAT_poll_interval_ = ui_->CAT_poll_interval_spin_box->value ();
  temp_rig_params.PTT_method_ = static_cast<TransceiverFactory::PTTMethod> (ui_->PTT_method_button_group->checkedId ());
  temp_rig_params.PTT_port_ = ui_->PTT_port_combo_box->currentText ();
  temp_rig_params.TX_audio_source_ = static_cast<TransceiverFactory::TXAudioSource> (ui_->TX_audio_source_button_group->checkedId ());
  temp_rig_params.split_mode_ = static_cast<TransceiverFactory::SplitMode> (ui_->split_mode_button_group->checkedId ());

  // open_rig() uses values from models so we use it to validate the
  // Transceiver settings before agreeing to accept the configuration
  if (temp_rig_params != rig_params_ && !open_rig ())
    {
      return;			// not accepting
    }
  sync_transceiver (true);	// force an update

  //
  // from here on we are bound to accept the new configuration
  // parameters so extract values from models and make them live
  //

  if (font_changed_)
    {
      font_changed_ = false;
      font_ = next_font_;
      QApplication::setFont (font_);
    }

  if (decoded_text_font_changed_)
    {
      decoded_text_font_changed_ = false;
      decoded_text_font_ = next_decoded_text_font_;
      Q_EMIT self_->decoded_text_font_changed (decoded_text_font_);
    }

  rig_params_ = temp_rig_params; // now we can go live with the rig
  // related configuration parameters

  // Check to see whether SoundInThread must be restarted,
  // and save user parameters.
  {
    auto const& device_name = ui_->sound_input_combo_box->currentText ();
    if (device_name != audio_input_device_.deviceName ())
      {
        auto const& default_device = QAudioDeviceInfo::defaultInputDevice ();
        if (device_name == default_device.deviceName ())
          {
            audio_input_device_ = default_device;
          }
        else
          {
            bool found {false};
            Q_FOREACH (auto const& d, QAudioDeviceInfo::availableDevices (QAudio::AudioInput))
              {
                if (device_name == d.deviceName ())
                  {
                    audio_input_device_ = d;
                    found = true;
                  }
              }
            if (!found)
              {
                audio_input_device_ = default_device;
              }
          }
        restart_sound_input_device_ = true;
      }
  }

  {
    auto const& device_name = ui_->sound_output_combo_box->currentText ();
    if (device_name != audio_output_device_.deviceName ())
      {
        auto const& default_device = QAudioDeviceInfo::defaultOutputDevice ();
        if (device_name == default_device.deviceName ())
          {
            audio_output_device_ = default_device;
          }
        else
          {
            bool found {false};
            Q_FOREACH (auto const& d, QAudioDeviceInfo::availableDevices (QAudio::AudioOutput))
              {
                if (device_name == d.deviceName ())
                  {
                    audio_output_device_ = d;
                    found = true;
                  }
              }
            if (!found)
              {
                audio_output_device_ = default_device;
              }
          }
        restart_sound_output_device_ = true;
      }
  }

  if (audio_input_channel_ != static_cast<AudioDevice::Channel> (ui_->sound_input_channel_combo_box->currentIndex ()))
    {
      audio_input_channel_ = static_cast<AudioDevice::Channel> (ui_->sound_input_channel_combo_box->currentIndex ());
      restart_sound_input_device_ = true;
    }
  Q_ASSERT (audio_input_channel_ <= AudioDevice::Right);

  if (audio_output_channel_ != static_cast<AudioDevice::Channel> (ui_->sound_output_channel_combo_box->currentIndex ()))
    {
      audio_output_channel_ = static_cast<AudioDevice::Channel> (ui_->sound_output_channel_combo_box->currentIndex ());
      restart_sound_output_device_ = true;
    }
  Q_ASSERT (audio_output_channel_ <= AudioDevice::Both);

  my_callsign_ = ui_->callsign_line_edit->text ();
  my_grid_ = ui_->grid_line_edit->text ();
  spot_to_psk_reporter_ = ui_->psk_reporter_check_box->isChecked ();
  id_interval_ = ui_->CW_id_interval_spin_box->value ();
  id_after_73_ = ui_->CW_id_after_73_check_box->isChecked ();
  tx_QSY_allowed_ = ui_->tx_QSY_check_box->isChecked ();
  monitor_off_at_startup_ = ui_->monitor_off_check_box->isChecked ();
  jt9w_bw_mult_ = ui_->jt9w_bandwidth_mult_combo_box->currentText ().toUInt ();
  jt9w_min_dt_ = static_cast<float> (ui_->jt9w_min_dt_double_spin_box->value ());
  jt9w_max_dt_ = static_cast<float> (ui_->jt9w_max_dt_double_spin_box->value ());
  log_as_RTTY_ = ui_->log_as_RTTY_check_box->isChecked ();
  report_in_comments_ = ui_->report_in_comments_check_box->isChecked ();
  prompt_to_log_ = ui_->prompt_to_log_check_box->isChecked ();
  insert_blank_ = ui_->insert_blank_check_box->isChecked ();
  DXCC_ = ui_->DXCC_check_box->isChecked ();
  clear_DX_ = ui_->clear_DX_check_box->isChecked ();
  miles_ = ui_->miles_check_box->isChecked ();
  quick_call_ = ui_->quick_call_check_box->isChecked ();
  disable_TX_on_73_ = ui_->disable_TX_on_73_check_box->isChecked ();
  watchdog_ = ui_->watchdog_check_box->isChecked ();
  TX_messages_ = ui_->TX_messages_check_box->isChecked ();
  data_mode_ = static_cast<DataMode> (ui_->TX_mode_button_group->checkedId ());
  save_directory_ = ui_->save_path_display_label->text ();

  if (macros_.stringList () != next_macros_.stringList ())
    {
      macros_.setStringList (next_macros_.stringList ());
    }

  if (frequencies_.frequencies () != next_frequencies_.frequencies ())
    {
      frequencies_ = next_frequencies_.frequencies ();
      frequencies_.sort (0);
    }

  if (stations_.stations () != next_stations_.stations ())
    {
      stations_ = next_stations_.stations ();
      stations_.sort (0);
    }
 
  write_settings ();		// make visible to all

  QDialog::accept();
}

void Configuration::impl::reject ()
{
  initialise_models ();		// reverts to settings as at exec ()

  // check if the Transceiver instance changed, in which case we need
  // to re open any prior Transceiver type
  if (rig_changed_)
    {
      if (have_rig_)
        {
          // we have to do this since the rig has been opened since we
          // were exec'ed even though it might fail
          open_rig ();
        }
      else
        {
          close_rig ();
        }
    }

  QDialog::reject ();
}

void Configuration::impl::message_box (QString const& reason, QString const& detail)
{
  QMessageBox mb;
  mb.setText (reason);
  if (!detail.isEmpty ())
    {
      mb.setDetailedText (detail);
    }
  mb.setStandardButtons (QMessageBox::Ok);
  mb.setDefaultButton (QMessageBox::Ok);
  mb.setIcon (QMessageBox::Critical);
  mb.exec ();
}

void Configuration::impl::on_font_push_button_clicked ()
{
  next_font_ = QFontDialog::getFont (&font_changed_, this);
}

void Configuration::impl::on_decoded_text_font_push_button_clicked ()
{
  next_decoded_text_font_ = QFontDialog::getFont (&decoded_text_font_changed_
                                                  , decoded_text_font_
                                                  , this
                                                  , tr ("WSJT-X Decoded Text Font Chooser")
#if QT_VERSION >= 0x050201
                                                  , QFontDialog::MonospacedFonts
#endif
                                                  );
}

void Configuration::impl::on_PTT_port_combo_box_activated (int /* index */)
{
  set_rig_invariants ();
}

void Configuration::impl::on_CAT_port_combo_box_activated (int /* index */)
{
  set_rig_invariants ();
}

void Configuration::impl::on_CAT_serial_baud_combo_box_currentIndexChanged (int /* index */)
{
  set_rig_invariants ();
}

void Configuration::impl::on_CAT_handshake_button_group_buttonClicked (int /* id */)
{
  set_rig_invariants ();
}

void Configuration::impl::on_rig_combo_box_currentIndexChanged (int /* index */)
{
  set_rig_invariants ();
}

void Configuration::impl::on_CAT_data_bits_button_group_buttonClicked (int /* id */)
{
  set_rig_invariants ();
}

void Configuration::impl::on_CAT_stop_bits_button_group_buttonClicked (int /* id */)
{
  set_rig_invariants ();
}

void Configuration::impl::on_CAT_poll_interval_spin_box_valueChanged (int /* value */)
{
  set_rig_invariants ();
}

void Configuration::impl::on_split_mode_button_group_buttonClicked (int /* id */)
{
  setup_split_ = true;
}

void Configuration::impl::on_test_CAT_push_button_clicked ()
{
  if (!validate ())
    {
      return;
    }

  ui_->test_CAT_push_button->setStyleSheet ({});
  if (open_rig ())
    {
      Q_EMIT sync (true);
    }

  set_rig_invariants ();
}

void Configuration::impl::on_test_PTT_push_button_clicked ()
{
  if (!validate ())
    {
      return;
    }

  Q_EMIT self_->transceiver_ptt ((ptt_state_ = !ptt_state_));

  ui_->test_PTT_push_button->setStyleSheet (ptt_state_ ? "QPushButton{background-color: red;"
                                            "border-style: outset; border-width: 1px; border-radius: 5px;"
                                            "border-color: black; min-width: 5em; padding: 3px;}"
                                            : "");
}

void Configuration::impl::on_CAT_DTR_check_box_toggled (bool /* checked */)
{
  set_rig_invariants ();
}

void Configuration::impl::on_CAT_RTS_check_box_toggled (bool /* checked */)
{
  set_rig_invariants ();
}

void Configuration::impl::on_PTT_method_button_group_buttonClicked (int /* id */)
{
  set_rig_invariants ();
}

void Configuration::impl::on_callsign_line_edit_editingFinished ()
{
  ui_->callsign_line_edit->setText (ui_->callsign_line_edit->text ().toUpper ());
}

void Configuration::impl::on_grid_line_edit_editingFinished ()
{
  auto text = ui_->grid_line_edit->text ();
  ui_->grid_line_edit->setText (text.left (4).toUpper () + text.mid (4).toLower ());
}

void Configuration::impl::on_sound_input_combo_box_currentTextChanged (QString const& text)
{
  default_audio_input_device_selected_ = QAudioDeviceInfo::defaultInputDevice ().deviceName () == text;
}

void Configuration::impl::on_sound_output_combo_box_currentTextChanged (QString const& text)
{
  default_audio_output_device_selected_ = QAudioDeviceInfo::defaultOutputDevice ().deviceName () == text;
}

void Configuration::impl::on_add_macro_line_edit_editingFinished ()
{
  ui_->add_macro_line_edit->setText (ui_->add_macro_line_edit->text ().toUpper ());
}

void Configuration::impl::on_delete_macro_push_button_clicked (bool /* checked */)
{
  auto selection_model = ui_->macros_list_view->selectionModel ();
  if (selection_model->hasSelection ())
    {
      // delete all selected items
      delete_selected_macros (selection_model->selectedRows ());
    }
}

void Configuration::impl::delete_macro ()
{
  auto selection_model = ui_->macros_list_view->selectionModel ();
  if (!selection_model->hasSelection ())
    {
      // delete item under cursor if any
      auto index = selection_model->currentIndex ();
      if (index.isValid ())
        {
          next_macros_.removeRow (index.row ());
        }
    }
  else
    {
      // delete the whole selection
      delete_selected_macros (selection_model->selectedRows ());
    }
}

void Configuration::impl::delete_selected_macros (QModelIndexList selected_rows)
{
  // sort in reverse row order so that we can delete without changing
  // indices underneath us
  qSort (selected_rows.begin (), selected_rows.end (), [] (QModelIndex const& lhs, QModelIndex const& rhs)
         {
           return rhs.row () < lhs.row (); // reverse row ordering
         });

  // now delete them
  Q_FOREACH (auto index, selected_rows)
    {
      next_macros_.removeRow (index.row ());
    }
}

void Configuration::impl::on_add_macro_push_button_clicked (bool /* checked */)
{
  if (next_macros_.insertRow (next_macros_.rowCount ()))
    {
      auto index = next_macros_.index (next_macros_.rowCount () - 1);
      ui_->macros_list_view->setCurrentIndex (index);
      next_macros_.setData (index, ui_->add_macro_line_edit->text ());
      ui_->add_macro_line_edit->clear ();
    }
}

void Configuration::impl::delete_frequencies ()
{
  auto selection_model = ui_->frequencies_table_view->selectionModel ();
  selection_model->select (selection_model->selection (), QItemSelectionModel::SelectCurrent | QItemSelectionModel::Rows);
  next_frequencies_.removeDisjointRows (selection_model->selectedRows ());
}

void Configuration::impl::insert_frequency ()
{
  if (QDialog::Accepted == frequency_dialog_->exec ())
    {
      ui_->frequencies_table_view->setCurrentIndex (next_frequencies_.add (frequency_dialog_->frequency ()));
    }
}

void Configuration::impl::delete_stations ()
{
  auto selection_model = ui_->stations_table_view->selectionModel ();
  selection_model->select (selection_model->selection (), QItemSelectionModel::SelectCurrent | QItemSelectionModel::Rows);
  next_stations_.removeDisjointRows (selection_model->selectedRows ());
}

void Configuration::impl::insert_station ()
{
  if (QDialog::Accepted == station_dialog_->exec ())
    {
      ui_->stations_table_view->setCurrentIndex (next_stations_.add (station_dialog_->station ()));
    }
}

void Configuration::impl::on_save_path_select_push_button_clicked (bool /* checked */)
{
  QFileDialog fd {this, tr ("Save Directory"), ui_->save_path_display_label->text ()};
  fd.setFileMode (QFileDialog::Directory);
  fd.setOption (QFileDialog::ShowDirsOnly);
  if (fd.exec ())
    {
      if (fd.selectedFiles ().size ())
        {
          ui_->save_path_display_label->setText (fd.selectedFiles ().at (0));
        }
    }
}

bool Configuration::impl::have_rig (bool open_if_closed)
{
  if (open_if_closed && !rig_active_ && !open_rig ())
    {
      QMessageBox::critical (this, "WSJT-X", tr ("Failed to open connection to rig"));
    }
  return rig_active_;
}

bool Configuration::impl::open_rig ()
{
  auto result = false;

  try
    {
      close_rig ();

      // create a new Transceiver object
      auto rig = transceiver_factory_.create (ui_->rig_combo_box->currentText ()
                                              , ui_->CAT_port_combo_box->currentText ()
                                              , ui_->CAT_serial_baud_combo_box->currentText ().toInt ()
                                              , static_cast<TransceiverFactory::DataBits> (ui_->CAT_data_bits_button_group->checkedId ())
                                              , static_cast<TransceiverFactory::StopBits> (ui_->CAT_stop_bits_button_group->checkedId ())
                                              , static_cast<TransceiverFactory::Handshake> (ui_->CAT_handshake_button_group->checkedId ())
                                              , ui_->CAT_DTR_check_box->isChecked ()
                                              , ui_->CAT_RTS_check_box->isChecked ()
                                              , static_cast<TransceiverFactory::PTTMethod> (ui_->PTT_method_button_group->checkedId ())
                                              , static_cast<TransceiverFactory::TXAudioSource> (ui_->TX_audio_source_button_group->checkedId ())
                                              , static_cast<TransceiverFactory::SplitMode> (ui_->split_mode_button_group->checkedId ())
                                              , ui_->PTT_port_combo_box->currentText ()
                                              , ui_->CAT_poll_interval_spin_box->value () * 1000
                                              , data_path_
                                              , &transceiver_thread_
                                              );

      // hook up Configuration transceiver control signals to Transceiver slots
      //
      // these connections cross the thread boundary
      connect (this, &Configuration::impl::frequency, rig.get (), &Transceiver::frequency);
      connect (this, &Configuration::impl::tx_frequency, rig.get (), &Transceiver::tx_frequency);
      connect (this, &Configuration::impl::mode, rig.get (), &Transceiver::mode);
      connect (this, &Configuration::impl::ptt, rig.get (), &Transceiver::ptt);
      connect (this, &Configuration::impl::sync, rig.get (), &Transceiver::sync);

      // hook up Transceiver signals to Configuration signals
      //
      // these connections cross the thread boundary
      connect (rig.get (), &Transceiver::update, this, &Configuration::impl::handle_transceiver_update);
      connect (rig.get (), &Transceiver::failure, this, &Configuration::impl::handle_transceiver_failure);

      // setup thread safe startup and close down semantics
      connect (this, &Configuration::impl::stop_transceiver, rig.get (), &Transceiver::stop);

      auto p = rig.release ();	// take ownership
      // schedule eventual destruction
      //
      // must be queued connection to avoid premature self-immolation
      // since finished signal is going to be emitted from the object
      // that will get destroyed in its own stop slot i.e. a same
      // thread signal to slot connection which by default will be
      // reduced to a method function call.
      connect (p, &Transceiver::finished, p, &Transceiver::deleteLater, Qt::QueuedConnection);

      ui_->test_CAT_push_button->setStyleSheet ({});
      rig_active_ = true;
      QTimer::singleShot (0, p, SLOT (start ())); // start rig on its thread
      result = true;
    }
  catch (std::exception const& e)
    {
      handle_transceiver_failure (e.what ());
    }

  rig_changed_ = true;
  return result;
}

void Configuration::impl::transceiver_frequency (Frequency f)
{
  if (set_mode () || cached_rig_state_.frequency () != f)
    {
      cached_rig_state_.frequency (f);

      // lookup offset
      transceiver_offset_ = stations_.offset (f);
      Q_EMIT frequency (f + transceiver_offset_);
    }
}

bool Configuration::impl::set_mode ()
{
  // Some rigs change frequency when switching between some modes so
  // we need to check if we change mode and not elide the frequency
  // setting in the same as the cached frequency.
  bool mode_changed {false};

  auto data_mode = static_cast<DataMode> (ui_->TX_mode_button_group->checkedId ());

  // Set mode if we are responsible for it.
  if (data_mode_USB == data_mode && cached_rig_state_.mode () != Transceiver::USB)
    {
      if (Transceiver::USB != cached_rig_state_.mode ())
        {
          cached_rig_state_.mode (Transceiver::USB);
          Q_EMIT mode (Transceiver::USB, cached_rig_state_.split () && data_mode_none != data_mode_);
          mode_changed = true;
        }
    }
  if (data_mode_data == data_mode && cached_rig_state_.mode () != Transceiver::DIG_U)
    {
      if (Transceiver::DIG_U != cached_rig_state_.mode ())
        {
          cached_rig_state_.mode (Transceiver::DIG_U);
          Q_EMIT mode (Transceiver::DIG_U, cached_rig_state_.split () && data_mode_none != data_mode_);
          mode_changed = true;
        }
    }

  return mode_changed;
}

void Configuration::impl::transceiver_tx_frequency (Frequency f)
{
  if (set_mode () || cached_rig_state_.tx_frequency () != f || cached_rig_state_.split () != !!f)
    {
      cached_rig_state_.tx_frequency (f);
      cached_rig_state_.split (f);

      // lookup offset if we are in split mode
      if (f)
        {
          transceiver_offset_ = stations_.offset (f);
          f += transceiver_offset_;
        }

      // Rationalise TX VFO mode if we ask for split and are
      // responsible for mode.
      Q_EMIT tx_frequency (f, cached_rig_state_.split () && data_mode_none != data_mode_);
    }
}

void Configuration::impl::transceiver_mode (MODE m)
{
  if (cached_rig_state_.mode () != m)
    {
      cached_rig_state_.mode (m);

      // Rationalise mode if we are responsible for it and in split mode.
      Q_EMIT mode (m, cached_rig_state_.split () && data_mode_none != data_mode_);
    }
}

void Configuration::impl::transceiver_ptt (bool on)
{
  set_mode ();

  cached_rig_state_.ptt (on);

  // pass this on regardless of cache
  Q_EMIT ptt (on);
}

void Configuration::impl::sync_transceiver (bool force_signal)
{
  // pass this on as cache must be ignored
  Q_EMIT sync (force_signal);
}

void Configuration::impl::handle_transceiver_update (TransceiverState state)
{
#if WSJT_TRACE_CAT
  qDebug () << "Configuration::handle_transceiver_update: Transceiver State:" << state;
#endif

  if (state.online ())
    {
      TransceiverFactory::SplitMode split_mode_selected;
      if (isVisible ())
        {
          ui_->test_CAT_push_button->setStyleSheet ("QPushButton {background-color: green;}");

          auto const& rig = ui_->rig_combo_box->currentText ();
          auto ptt_method = static_cast<TransceiverFactory::PTTMethod> (ui_->PTT_method_button_group->checkedId ());
          auto CAT_PTT_enabled = transceiver_factory_.has_CAT_PTT (rig);
          ui_->test_PTT_push_button->setEnabled ((TransceiverFactory::PTT_method_CAT == ptt_method && CAT_PTT_enabled)
                                                 || TransceiverFactory::PTT_method_DTR == ptt_method
                                                 || TransceiverFactory::PTT_method_RTS == ptt_method);

          set_mode ();

          // Follow the setup choice.
          split_mode_selected = static_cast<TransceiverFactory::SplitMode> (ui_->split_mode_button_group->checkedId ());
        }
      else
        {
          // Follow the rig unless configuration has been changed.
          split_mode_selected = static_cast<TransceiverFactory::SplitMode> (rig_params_.split_mode_);

          if (enforce_mode_and_split_)
            {
              if ((TransceiverFactory::split_mode_none != split_mode_selected) != state.split ())
                {
                  if (!setup_split_)
                    {
                      // Rig split mode isn't consistent with settings so
                      // change settings.
                      //
                      // For rigs that can't report split mode changes
                      // (e.g.Icom) this is going to confuse operators, but
                      // what can we do if they change the rig?
                      // auto split_mode = state.split () ? TransceiverFactory::split_mode_rig : TransceiverFactory::split_mode_none;
                      // rig_params_.split_mode_ = split_mode;
                      // ui_->split_mode_button_group->button (split_mode)->setChecked (true);
                      // split_mode_selected = split_mode;
                      setup_split_ = true;

                      // Q_EMIT self_->transceiver_failure (tr ("Rig split mode setting not consistent with WSJT-X settings. Changing WSJT-X settings for you."));
                      Q_EMIT self_->transceiver_failure (tr ("Rig split mode setting not consistent with WSJT-X settings."));
                    }
                }

              set_mode ();
            }
        }

      // One time rig setup split
      if (setup_split_ && cached_rig_state_.split () != state.split ())
        {
          Q_EMIT tx_frequency (TransceiverFactory::split_mode_none != split_mode_selected ? state.tx_frequency () : 0, true);
        }
      setup_split_ = false;
    }
  else
    {
      close_rig ();
    }

  cached_rig_state_ = state;

  // take off offset
  cached_rig_state_.frequency (cached_rig_state_.frequency () - transceiver_offset_);
  if (cached_rig_state_.tx_frequency ())
    {
      cached_rig_state_.tx_frequency (cached_rig_state_.tx_frequency () - transceiver_offset_);
    }

  // pass on to clients
  Q_EMIT self_->transceiver_update (cached_rig_state_);
}

void Configuration::impl::handle_transceiver_failure (QString reason)
{
#if WSJT_TRACE_CAT
  qDebug () << "Configuration::handle_transceiver_failure: reason:" << reason;
#endif

  close_rig ();

  if (isVisible ())
    {
      message_box (tr ("Rig failure"), reason);
    }
  else
    {
      // pass on if our dialog isn't active
      Q_EMIT self_->transceiver_failure (reason);
    }
}

void Configuration::impl::close_rig ()
{
  ui_->test_PTT_push_button->setStyleSheet ({});
  ui_->test_PTT_push_button->setEnabled (false);
  ptt_state_ = false;

  // revert to no rig configured
  if (rig_active_)
    {
      ui_->test_CAT_push_button->setStyleSheet ("QPushButton {background-color: red;}");
      Q_EMIT stop_transceiver ();
      rig_active_ = false;
    }
}

// load the available audio devices into the selection combo box and
// select the default device if the current device isn't set or isn't
// available
bool Configuration::impl::load_audio_devices (QAudio::Mode mode, QComboBox * combo_box, QAudioDeviceInfo * device)
{
  using std::copy;
  using std::back_inserter;

  bool result {false};

  combo_box->clear ();

  int current_index = -1;
  int default_index = -1;

  int extra_items {0};

  auto const& default_device = (mode == QAudio::AudioInput ? QAudioDeviceInfo::defaultInputDevice () : QAudioDeviceInfo::defaultOutputDevice ());

  // deal with special default audio devices on Windows
  if ("Default Input Device" == default_device.deviceName ()
      || "Default Output Device" == default_device.deviceName ())
    {
      default_index = 0;

      QList<QVariant> channel_counts;
      auto scc = default_device.supportedChannelCounts ();
      copy (scc.cbegin (), scc.cend (), back_inserter (channel_counts));

      combo_box->addItem (default_device.deviceName (), channel_counts);
      ++extra_items;
      if (default_device == *device)
        {
          current_index = 0;
          result = true;
        }
    }

  Q_FOREACH (auto const& p, QAudioDeviceInfo::availableDevices (mode))
    {
      // convert supported channel counts into something we can store in the item model
      QList<QVariant> channel_counts;
      auto scc = p.supportedChannelCounts ();
      copy (scc.cbegin (), scc.cend (), back_inserter (channel_counts));

      combo_box->addItem (p.deviceName (), channel_counts);
      if (p == *device)
        {
          current_index = combo_box->count () - 1;
        }
      else if (p == default_device)
        {
          default_index = combo_box->count () - 1;
        }
    }
  if (current_index < 0)	// not found - use default
    {
      *device = default_device;
      result = true;
      current_index = default_index;
    }
  combo_box->setCurrentIndex (current_index);

  return result;
}

// enable only the channels that are supported by the selected audio device
void Configuration::impl::update_audio_channels (QComboBox const * source_combo_box, int index, QComboBox * combo_box, bool allow_both)
{
  // disable all items
  for (int i (0); i < combo_box->count (); ++i)
    {
      combo_box->setItemData (i, combo_box_item_disabled, Qt::UserRole - 1);
    }

  Q_FOREACH (QVariant const& v, source_combo_box->itemData (index).toList ())
    {
      // enable valid options
      int n {v.toInt ()};
      if (2 == n)
        {
          combo_box->setItemData (AudioDevice::Left, combo_box_item_enabled, Qt::UserRole - 1);
          combo_box->setItemData (AudioDevice::Right, combo_box_item_enabled, Qt::UserRole - 1);
          if (allow_both)
            {
              combo_box->setItemData (AudioDevice::Both, combo_box_item_enabled, Qt::UserRole - 1);
            }
        }
      else if (1 == n)
        {
          combo_box->setItemData (AudioDevice::Mono, combo_box_item_enabled, Qt::UserRole - 1);
        }
    }
}

// load all the supported rig names into the selection combo box
void Configuration::impl::enumerate_rigs ()
{
  ui_->rig_combo_box->clear ();

  auto rigs = transceiver_factory_.supported_transceivers ();

  for (auto r = rigs.cbegin (); r != rigs.cend (); ++r)
    {
      if ("None" == r.key ())
        {
          // put None first
          ui_->rig_combo_box->insertItem (0, r.key (), r.value ().model_number_);
        }
      else
        {
          ui_->rig_combo_box->addItem (r.key (), r.value ().model_number_);
        }
    }

  ui_->rig_combo_box->setCurrentText (rig_params_.rig_name_);
}

void Configuration::impl::fill_port_combo_box (QComboBox * cb)
{
  auto current_text = cb->currentText ();

  cb->clear ();

#ifdef WIN32

  for (int i {1}; i < 100; ++i)
    {
      auto item = "COM" + QString::number (i);
      cb->addItem (item);
    }
  cb->addItem("USB");

#else

  QStringList ports = {
    "/dev/ttyS0"
    , "/dev/ttyS1"
    , "/dev/ttyS2"
    , "/dev/ttyS3"
    , "/dev/ttyS4"
    , "/dev/ttyS5"
    , "/dev/ttyS6"
    , "/dev/ttyS7"
    , "/dev/ttyUSB0"
    , "/dev/ttyUSB1"
    , "/dev/ttyUSB2"
    , "/dev/ttyUSB3"
  };
  cb->addItems (ports);

#endif

  cb->setEditText (current_text);
}


inline
bool operator != (RigParams const& lhs, RigParams const& rhs)
{
  return
    lhs.CAT_serial_port_ != rhs.CAT_serial_port_
    || lhs.CAT_network_port_ != rhs.CAT_network_port_
    || lhs.CAT_baudrate_ != rhs.CAT_baudrate_
    || lhs.CAT_data_bits_ != rhs.CAT_data_bits_
    || lhs.CAT_stop_bits_ != rhs.CAT_stop_bits_
    || lhs.CAT_handshake_ != rhs.CAT_handshake_
    || lhs.CAT_DTR_always_on_ != rhs.CAT_DTR_always_on_
    || lhs.CAT_RTS_always_on_ != rhs.CAT_RTS_always_on_
    || lhs.CAT_poll_interval_ != rhs.CAT_poll_interval_
    || lhs.PTT_method_ != rhs.PTT_method_
    || lhs.PTT_port_ != rhs.PTT_port_
    || lhs.TX_audio_source_ != rhs.TX_audio_source_
    || lhs.split_mode_ != rhs.split_mode_
    || lhs.rig_name_ != rhs.rig_name_;
}


#if !defined (QT_NO_DEBUG_STREAM)
ENUM_QDEBUG_OPS_IMPL (Configuration, DataMode);
#endif

ENUM_QDATASTREAM_OPS_IMPL (Configuration, DataMode);

ENUM_CONVERSION_OPS_IMPL (Configuration, DataMode);
