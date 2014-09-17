#ifndef TRANSCEIVER_FACTORY_HPP__
#define TRANSCEIVER_FACTORY_HPP__

#include <memory>

#include <QObject>
#include <QMap>

#include "Transceiver.hpp"

#include "qt_helpers.hpp"

class QString;
class QThread;
class QDir;

//
// Transceiver Factory
//
class TransceiverFactory
  : public QObject
{
  Q_OBJECT;
  Q_ENUMS (DataBits StopBits Handshake PTTMethod TXAudioSource SplitMode);

private:
  Q_DISABLE_COPY (TransceiverFactory);

public:
  //
  // Capabilities of a Transceiver that can be determined without
  // actually instantiating one, these are for use in Configuration
  // GUI behaviour determination
  //
  struct Capabilities
  {
    enum PortType {none, serial, network};

    explicit Capabilities (int model_number = 0
                           , PortType port_type = none
                           , bool has_CAT_PTT = false
                           , bool has_CAT_PTT_mic_data = false
                           , bool has_CAT_indirect_serial_PTT = false
                           , bool asynchronous = false)
      : model_number_ {model_number}
      , port_type_ {port_type}
      , has_CAT_PTT_ {has_CAT_PTT}
      , has_CAT_PTT_mic_data_ {has_CAT_PTT_mic_data}
      , has_CAT_indirect_serial_PTT_ {has_CAT_indirect_serial_PTT}
      , asynchronous_ {asynchronous}
    {
    }

    int model_number_;
    PortType port_type_;
    bool has_CAT_PTT_;
    bool has_CAT_PTT_mic_data_;
    bool has_CAT_indirect_serial_PTT_; // OmniRig controls RTS/DTR via COM interface
    bool asynchronous_;
  };

  //
  // Dictionary of Transceiver types Capabilities
  //
  typedef QMap<QString, Capabilities> Transceivers;

  //
  // various Transceiver parameters
  //
  enum DataBits {seven_data_bits = 7, eight_data_bits};
  enum StopBits {one_stop_bit = 1, two_stop_bits};
  enum Handshake {handshake_none, handshake_XonXoff, handshake_hardware};
  enum PTTMethod {PTT_method_VOX, PTT_method_CAT, PTT_method_DTR, PTT_method_RTS};
  enum TXAudioSource {TX_audio_source_front, TX_audio_source_rear};
  enum SplitMode {split_mode_none, split_mode_rig, split_mode_emulate};

  TransceiverFactory ();

  static char const * const basic_transceiver_name_; // dummy transceiver is basic model

  //
  // fetch all supported rigs as a list of name and model id
  //
  Transceivers const& supported_transceivers () const;

  // supported model queries
  Capabilities::PortType CAT_port_type (QString const& name) const; // how to talk to CAT
  bool has_CAT_PTT (QString const& name) const;	// can be keyed via CAT
  bool has_CAT_PTT_mic_data (QString const& name) const; // Tx audio port is switchable via CAT
  bool has_CAT_indirect_serial_PTT (QString const& name) const; // Can PTT via CAT port use DTR or RTS (OmniRig for example)
  bool has_asynchronous_CAT (QString const& name) const; // CAT asynchronous rather than polled

  // make a new Transceiver instance
  //
  // cat_port, cat_baud, cat_data_bits, cat_stop_bits, cat_handshake,
  // cat_dtr_alway_on, cat_rts_always_on are only relevant to
  // interfaces that are served by hamlib
  //
  // PTT port and to some extent ptt_type are independent of interface
  // type
  //
  std::unique_ptr<Transceiver> create (QString const& name // from supported_transceivers () key
                                       , QString const& cat_port // serial port device name or empty
                                       , int cat_baud
                                       , DataBits cat_data_bits
                                       , StopBits cat_stop_bits
                                       , Handshake cat_handshake
                                       , bool cat_dtr_always_on	// to power interface
                                       , bool cat_rts_always_on	// to power inteface
                                       , PTTMethod ptt_type // "CAT" | "DTR" | "RTS" | "VOX"
                                       , TXAudioSource ptt_use_data_ptt	// some rigs allow audio routing to Mic/Data connector
                                       , SplitMode split_mode // how to support split TX mode
                                       , QString const& ptt_port // serial port device name or special value "CAT"
                                       , int poll_interval // in milliseconds for interfaces that require polling for parameter changes
                                       , QDir const& data_path
                                       , QThread * target_thread = nullptr
                                       );
  
private:
  Transceivers transceivers_;
};

//
// boilerplate routines to make enum types useable and debuggable in
// Qt
//
Q_DECLARE_METATYPE (TransceiverFactory::DataBits);
Q_DECLARE_METATYPE (TransceiverFactory::StopBits);
Q_DECLARE_METATYPE (TransceiverFactory::Handshake);
Q_DECLARE_METATYPE (TransceiverFactory::PTTMethod);
Q_DECLARE_METATYPE (TransceiverFactory::TXAudioSource);
Q_DECLARE_METATYPE (TransceiverFactory::SplitMode);

#if !defined (QT_NO_DEBUG_STREAM)
ENUM_QDEBUG_OPS_DECL (TransceiverFactory, DataBits);
ENUM_QDEBUG_OPS_DECL (TransceiverFactory, StopBits);
ENUM_QDEBUG_OPS_DECL (TransceiverFactory, Handshake);
ENUM_QDEBUG_OPS_DECL (TransceiverFactory, PTTMethod);
ENUM_QDEBUG_OPS_DECL (TransceiverFactory, TXAudioSource);
ENUM_QDEBUG_OPS_DECL (TransceiverFactory, SplitMode);
#endif

ENUM_QDATASTREAM_OPS_DECL (TransceiverFactory, DataBits);
ENUM_QDATASTREAM_OPS_DECL (TransceiverFactory, StopBits);
ENUM_QDATASTREAM_OPS_DECL (TransceiverFactory, Handshake);
ENUM_QDATASTREAM_OPS_DECL (TransceiverFactory, PTTMethod);
ENUM_QDATASTREAM_OPS_DECL (TransceiverFactory, TXAudioSource);
ENUM_QDATASTREAM_OPS_DECL (TransceiverFactory, SplitMode);

ENUM_CONVERSION_OPS_DECL (TransceiverFactory, DataBits);
ENUM_CONVERSION_OPS_DECL (TransceiverFactory, StopBits);
ENUM_CONVERSION_OPS_DECL (TransceiverFactory, Handshake);
ENUM_CONVERSION_OPS_DECL (TransceiverFactory, PTTMethod);
ENUM_CONVERSION_OPS_DECL (TransceiverFactory, TXAudioSource);
ENUM_CONVERSION_OPS_DECL (TransceiverFactory, SplitMode);

#endif
