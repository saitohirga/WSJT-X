#ifndef CONFIGURATION_HPP_
#define CONFIGURATION_HPP_

#include <QObject>

#include "Radio.hpp"
#include "AudioDevice.hpp"
#include "Transceiver.hpp"

#include "pimpl_h.hpp"

class QSettings;
class QWidget;
class QAudioDeviceInfo;
class QString;
class QDir;
class QFont;
class Bands;
class FrequencyList;
class StationList;
class QStringListModel;

//
// Class Configuration
//
//  Encapsulates the control, access  and, persistence of user defined
//  settings for the wsjtx GUI.  Setting values are accessed through a
//  QDialog window containing concept orientated tab windows.
//
// Responsibilities
//
//  Provides management of  the CAT and PTT  rig interfaces, providing
//  control access  via a minimal generic  set of Qt slots  and status
//  updates via Qt signals.  Internally  the rig control capability is
//  farmed out  to a  separate thread  since many  of the  rig control
//  functions are blocking.
//
//  All user  settings required by  the wsjtx GUI are  exposed through
//  query methods.  Settings only become  visible once they  have been
//  accepted by the user which is  done by clicking the "OK" button on
//  the settings dialog.
//
//  The QSettings instance  passed to the constructor is  used to read
//  and write user settings.
//
//  Pointers to three QAbstractItemModel  objects are provided to give
//  access to amateur band  information, user working frequencies and,
//  user operating  band information.  These porovide  consistent data
//  models that can  be used in GUI lists or  tables or simply queried
//  for user defined bands, default operating frequencies and, station
//  descriptions.
//
class Configuration final
  : public QObject
{
  Q_OBJECT;
  Q_ENUMS (DataMode);

public:
  using MODE = Transceiver::MODE;
  using TransceiverState = Transceiver::TransceiverState;
  using Frequency = Radio::Frequency;

  enum DataMode {data_mode_none, data_mode_USB, data_mode_data};

  explicit Configuration (QSettings * settings, QWidget * parent = nullptr);
  ~Configuration ();

  int exec ();

  QDir temp_dir () const;
  QDir doc_dir () const;

  QAudioDeviceInfo const& audio_input_device () const;
  AudioDevice::Channel audio_input_channel () const;
  QAudioDeviceInfo const& audio_output_device () const;
  AudioDevice::Channel audio_output_channel () const;

  // These query methods should be used after a call to exec() to
  // determine if either the audio input or audio output stream
  // parameters have changed. The respective streams should be
  // re-opened if they return true.
  bool restart_audio_input () const;
  bool restart_audio_output () const;

  QString my_callsign () const;
  QString my_grid () const;
  QFont decoded_text_font () const;
  qint32 id_interval () const;
  bool id_after_73 () const;
  bool tx_QSY_allowed () const;
  bool spot_to_psk_reporter () const;
  bool monitor_off_at_startup () const;
  bool monitor_last_used () const;
  bool log_as_RTTY () const;
  bool report_in_comments () const;
  bool prompt_to_log () const;
  bool insert_blank () const;
  bool DXCC () const;
  bool clear_DX () const;
  bool miles () const;
  bool quick_call () const;
  bool disable_TX_on_73 () const;
  bool watchdog () const;
  bool TX_messages () const;
  bool split_mode () const;
  Bands * bands ();
  FrequencyList * frequencies ();
  StationList * stations ();
  QStringListModel * macros ();
  QDir save_directory () const;
  QString rig_name () const;
  unsigned jt9w_bw_mult () const;
  float jt9w_min_dt () const;
  float jt9w_max_dt () const;
  QColor color_CQ () const;
  QColor color_MyCall () const;
  QColor color_TxMsg () const;
  QColor color_DXCC () const;
  QColor color_NewCall () const;

  // This method queries if a CAT and PTT connection is operational,
  //
  // It also doubles as an initialisation method when the
  // open_if_closed parameter is passed as true.
  bool transceiver_online (bool open_if_closed = false);

  // Close down connection to rig.
  void transceiver_offline ();

  // Set transceiver frequency in Hertz.
  Q_SLOT void transceiver_frequency (Frequency);

  // Setting a non zero TX frequency means split operation
  // rationalise_mode means ensure TX uses same mode as RX.
  Q_SLOT void transceiver_tx_frequency (Frequency = 0u);

  // Set transceiver mode.
  //
  // Rationalise means ensure TX uses same mode as RX.
  Q_SLOT void transceiver_mode (MODE);

  // Set/unset PTT.
  //
  // Note that this must be called even if VOX PTT is selected since
  // the "Emulate Split" mode requires PTT information to coordinate
  // frequency changes.
  Q_SLOT void transceiver_ptt (bool = true);

  // Attempt to (re-)synchronise transceiver state.
  //
  // Force signal guarantees either a transceiver_update or a
  // transceiver_failure signal.
  //
  // The enforce_mode_and_split parameter ensures that future
  // transceiver updates have the correct mode and split setting
  // i.e. the transceiver is ready for use.
  Q_SLOT void sync_transceiver (bool force_signal = false, bool enforce_mode_and_split = false);


  //
  // This signal indicates that a font has been selected and accepted
  // for the decoded text.
  //
  Q_SIGNAL void decoded_text_font_changed (QFont);


  //
  // These signals are emitted and reflect transceiver state changes
  //

  // signals a change in one of the TransceiverState members
  Q_SIGNAL void transceiver_update (Transceiver::TransceiverState) const;

  // Signals a failure of a control rig CAT or PTT connection.
  //
  // A failed rig CAT or PTT connection is fatal and the underlying
  // connections are closed automatically. The connections can be
  // re-established with a call to transceiver_online(true) assuming
  // the fault condition has been rectified or is transient.
  Q_SIGNAL void transceiver_failure (QString reason) const;

private:
  class impl;
  pimpl<impl> m_;
};

Q_DECLARE_METATYPE (Configuration::DataMode);

#if !defined (QT_NO_DEBUG_STREAM)
ENUM_QDEBUG_OPS_DECL (Configuration, DataMode);
#endif

ENUM_QDATASTREAM_OPS_DECL (Configuration, DataMode);

ENUM_CONVERSION_OPS_DECL (Configuration, DataMode);

#endif
