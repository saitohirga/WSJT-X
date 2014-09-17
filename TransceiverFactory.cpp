#include "TransceiverFactory.hpp"

#include <QMetaType>

#include "HamlibTransceiver.hpp"
#include "DXLabSuiteCommanderTransceiver.hpp"
#include "HRDTransceiver.hpp"
#include "EmulateSplitTransceiver.hpp"

#if defined (WIN32)
#include "OmniRigTransceiver.hpp"
#endif

#include "moc_TransceiverFactory.cpp"

// we use the hamlib "Hamlib Dummy" transceiver for non-CAT radios,
// this allows us to still use the hamlib PTT control features for a
// unified PTT control solution

char const * const TransceiverFactory::basic_transceiver_name_ = "None";

namespace
{
  struct init
  {
    init ()
    {
      qRegisterMetaType<TransceiverFactory::DataBits> ("TransceiverFactory::DataBits");
      qRegisterMetaTypeStreamOperators<TransceiverFactory::DataBits> ("TransceiverFactory::DataBits");
      qRegisterMetaType<TransceiverFactory::StopBits> ("TransceiverFactory::StopBits");
      qRegisterMetaTypeStreamOperators<TransceiverFactory::StopBits> ("TransceiverFactory::StopBits");
      qRegisterMetaType<TransceiverFactory::Handshake> ("TransceiverFactory::Handshake");
      qRegisterMetaTypeStreamOperators<TransceiverFactory::Handshake> ("TransceiverFactory::Handshake");
      qRegisterMetaType<TransceiverFactory::PTTMethod> ("TransceiverFactory::PTTMethod");
      qRegisterMetaTypeStreamOperators<TransceiverFactory::PTTMethod> ("TransceiverFactory::PTTMethod");
      qRegisterMetaType<TransceiverFactory::TXAudioSource> ("TransceiverFactory::TXAudioSource");
      qRegisterMetaTypeStreamOperators<TransceiverFactory::TXAudioSource> ("TransceiverFactory::TXAudioSource");
      qRegisterMetaType<TransceiverFactory::SplitMode> ("TransceiverFactory::SplitMode");
      qRegisterMetaTypeStreamOperators<TransceiverFactory::SplitMode> ("TransceiverFactory::SplitMode");
    }
  } static_initializer;

  enum				// supported non-hamlib radio interfaces
    {
      NonHamlibBaseId = 9899
      , CommanderId
      , HRDId
      , OmniRigOneId
      , OmniRigTwoId
    };
}

TransceiverFactory::TransceiverFactory ()
{
  HamlibTransceiver::register_transceivers (&transceivers_);
  DXLabSuiteCommanderTransceiver::register_transceivers (&transceivers_, CommanderId);
  HRDTransceiver::register_transceivers (&transceivers_, HRDId);
  
#if defined (WIN32)
  // OmniRig is ActiveX/COM server so only on Windows
  OmniRigTransceiver::register_transceivers (&transceivers_, OmniRigOneId, OmniRigTwoId);
#endif
}

auto TransceiverFactory::supported_transceivers () const -> Transceivers const&
{
  return transceivers_;
}

auto TransceiverFactory::CAT_port_type (QString const& name) const -> Capabilities::PortType
{
  return supported_transceivers ()[name].port_type_;
}

bool TransceiverFactory::has_CAT_PTT (QString const& name) const
{
  return
    supported_transceivers ()[name].has_CAT_PTT_
    || supported_transceivers ()[name].model_number_ > NonHamlibBaseId;
}

bool TransceiverFactory::has_CAT_PTT_mic_data (QString const& name) const
{
  return supported_transceivers ()[name].has_CAT_PTT_mic_data_;
}

bool TransceiverFactory::has_CAT_indirect_serial_PTT (QString const& name) const
{
  return supported_transceivers ()[name].has_CAT_indirect_serial_PTT_;
}

bool TransceiverFactory::has_asynchronous_CAT (QString const& name) const
{
  return supported_transceivers ()[name].asynchronous_;
}

std::unique_ptr<Transceiver> TransceiverFactory::create (QString const& name
                                                         , QString const& cat_port
                                                         , int cat_baud
                                                         , DataBits cat_data_bits
                                                         , StopBits cat_stop_bits
                                                         , Handshake cat_handshake
                                                         , bool cat_dtr_always_on
                                                         , bool cat_rts_always_on
                                                         , PTTMethod ptt_type
                                                         , TXAudioSource ptt_use_data_ptt
                                                         , SplitMode split_mode
                                                         , QString const& ptt_port
                                                         , int poll_interval
                                                         , QDir const& data_path
                                                         , QThread * target_thread
                                                         )
{
  std::unique_ptr<Transceiver> result;
  switch (supported_transceivers ()[name].model_number_)
    {
    case CommanderId:
      {
        // we start with a dummy HamlibTransceiver object instance that can support direct PTT
        std::unique_ptr<TransceiverBase> basic_transceiver {
          new HamlibTransceiver {
            supported_transceivers ()[basic_transceiver_name_].model_number_
              , cat_port
              , cat_baud
              , cat_data_bits
              , cat_stop_bits
              , cat_handshake
              , cat_dtr_always_on
              , cat_rts_always_on
              , ptt_type
              , ptt_use_data_ptt
              , "CAT" == ptt_port ? "" : ptt_port
              }
        };
        if (target_thread)
          {
            basic_transceiver.get ()->moveToThread (target_thread);
          }

        // wrap the basic Transceiver object instance with a decorator object that talks to DX Lab Suite Commander
        result.reset (new DXLabSuiteCommanderTransceiver {std::move (basic_transceiver), cat_port, PTT_method_CAT == ptt_type, poll_interval});
        if (target_thread)
          {
            result.get ()->moveToThread (target_thread);
          }
      }
      break;

    case HRDId:
      {
        // we start with a dummy HamlibTransceiver object instance that can support direct PTT
        std::unique_ptr<TransceiverBase> basic_transceiver {
          new HamlibTransceiver {
            supported_transceivers ()[basic_transceiver_name_].model_number_
              , cat_port
              , cat_baud
              , cat_data_bits
              , cat_stop_bits
              , cat_handshake
              , cat_dtr_always_on
              , cat_rts_always_on
              , ptt_type
              , ptt_use_data_ptt
              , "CAT" == ptt_port ? "" : ptt_port
              }
        };
        if (target_thread)
          {
            basic_transceiver.get ()->moveToThread (target_thread);
          }

        // wrap the basic Transceiver object instance with a decorator object that talks to ham Radio Deluxe
        result.reset (new HRDTransceiver {std::move (basic_transceiver), cat_port, PTT_method_CAT == ptt_type, poll_interval, data_path});
        if (target_thread)
          {
            result.get ()->moveToThread (target_thread);
          }
      }
      break;

#if defined (WIN32)
    case OmniRigOneId:
      {
        // we start with a dummy HamlibTransceiver object instance that can support direct PTT
        std::unique_ptr<TransceiverBase> basic_transceiver {
          new HamlibTransceiver {
            supported_transceivers ()[basic_transceiver_name_].model_number_
              , cat_port
              , cat_baud
              , cat_data_bits
              , cat_stop_bits
              , cat_handshake
              , cat_dtr_always_on
              , cat_rts_always_on
              , ptt_type
              , ptt_use_data_ptt
              , "CAT" == ptt_port ? "" : ptt_port
              }
        };
        if (target_thread)
          {
            basic_transceiver.get ()->moveToThread (target_thread);
          }

        // wrap the basic Transceiver object instance with a decorator object that talks to OmniRig rig one
        result.reset (new OmniRigTransceiver {std::move (basic_transceiver), OmniRigTransceiver::One, ptt_type, ptt_port});
        if (target_thread)
          {
            result.get ()->moveToThread (target_thread);
          }
      }
      break;

    case OmniRigTwoId:
      {
        // we start with a dummy HamlibTransceiver object instance that can support direct PTT
        std::unique_ptr<TransceiverBase> basic_transceiver {
          new HamlibTransceiver {
            supported_transceivers ()[basic_transceiver_name_].model_number_
              , cat_port
              , cat_baud
              , cat_data_bits
              , cat_stop_bits
              , cat_handshake
              , cat_dtr_always_on
              , cat_rts_always_on
              , ptt_type
              , ptt_use_data_ptt
              , "CAT" == ptt_port ? "" : ptt_port
              }
        };
        if (target_thread)
          {
            basic_transceiver.get ()->moveToThread (target_thread);
          }

        // wrap the basic Transceiver object instance with a decorator object that talks to OmniRig rig two
        result.reset (new OmniRigTransceiver {std::move (basic_transceiver), OmniRigTransceiver::Two, ptt_type, ptt_port});
        if (target_thread)
          {
            result.get ()->moveToThread (target_thread);
          }
      }
      break;
#endif

    default:
      result.reset (new HamlibTransceiver {
          supported_transceivers ()[name].model_number_
            , cat_port
            , cat_baud
            , cat_data_bits
            , cat_stop_bits
            , cat_handshake
            , cat_dtr_always_on
            , cat_rts_always_on
            , ptt_type
            , ptt_use_data_ptt
            , "CAT" == ptt_port ? cat_port : ptt_port
            , poll_interval
            });
      if (target_thread)
        {
          result.get ()->moveToThread (target_thread);
        }
      break;
    }

  if (split_mode_emulate == split_mode)
    {
      // wrap the Transceiver object instance with a decorator that emulates split mode
      result.reset (new EmulateSplitTransceiver {std::move (result)});
      if (target_thread)
        {
          result.get ()->moveToThread (target_thread);
        }
    }

  return std::move (result);
}

#if !defined (QT_NO_DEBUG_STREAM)
ENUM_QDEBUG_OPS_IMPL (TransceiverFactory, DataBits);
ENUM_QDEBUG_OPS_IMPL (TransceiverFactory, StopBits);
ENUM_QDEBUG_OPS_IMPL (TransceiverFactory, Handshake);
ENUM_QDEBUG_OPS_IMPL (TransceiverFactory, PTTMethod);
ENUM_QDEBUG_OPS_IMPL (TransceiverFactory, TXAudioSource);
ENUM_QDEBUG_OPS_IMPL (TransceiverFactory, SplitMode);
#endif

ENUM_QDATASTREAM_OPS_IMPL (TransceiverFactory, DataBits);
ENUM_QDATASTREAM_OPS_IMPL (TransceiverFactory, StopBits);
ENUM_QDATASTREAM_OPS_IMPL (TransceiverFactory, Handshake);
ENUM_QDATASTREAM_OPS_IMPL (TransceiverFactory, PTTMethod);
ENUM_QDATASTREAM_OPS_IMPL (TransceiverFactory, TXAudioSource);
ENUM_QDATASTREAM_OPS_IMPL (TransceiverFactory, SplitMode);

ENUM_CONVERSION_OPS_IMPL (TransceiverFactory, DataBits);
ENUM_CONVERSION_OPS_IMPL (TransceiverFactory, StopBits);
ENUM_CONVERSION_OPS_IMPL (TransceiverFactory, Handshake);
ENUM_CONVERSION_OPS_IMPL (TransceiverFactory, PTTMethod);
ENUM_CONVERSION_OPS_IMPL (TransceiverFactory, TXAudioSource);
ENUM_CONVERSION_OPS_IMPL (TransceiverFactory, SplitMode);
