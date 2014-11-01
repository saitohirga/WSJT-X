#include "OmniRigTransceiver.hpp"

#include <QTimer>
#include <QDebug>

#include <objbase.h>

#include "moc_OmniRigTransceiver.cpp"

namespace
{
  auto constexpr OmniRig_transceiver_one_name = "OmniRig Rig 1";
  auto constexpr OmniRig_transceiver_two_name = "OmniRig Rig 2";
}

auto OmniRigTransceiver::map_mode (OmniRig::RigParamX param) -> MODE
{
  if (param & OmniRig::PM_CW_U)
    {
      return CW_R;
    }
  else if (param & OmniRig::PM_CW_L)
    {
      return CW;
    }
  else if (param & OmniRig::PM_SSB_U)
    {
      return USB;
    }
  else if (param & OmniRig::PM_SSB_L)
    {
      return LSB;
    }
  else if (param & OmniRig::PM_DIG_U)
    {
      return DIG_U;
    }
  else if (param & OmniRig::PM_DIG_L)
    {
      return DIG_L;
    }
  else if (param & OmniRig::PM_AM)
    {
      return AM;
    }
  else if (param & OmniRig::PM_FM)
    {
      return FM;
    }

#if WSJT_TRACE_CAT
  qDebug () << "OmniRig map_mode unrecognized mode";
#endif

  throw error {tr ("OmniRig: unrecognized mode")};
}

OmniRig::RigParamX OmniRigTransceiver::map_mode (MODE mode)
{
  switch (mode)
    {
    case AM: return OmniRig::PM_AM;
    case CW: return OmniRig::PM_CW_L;
    case CW_R: return OmniRig::PM_CW_U;
    case USB: return OmniRig::PM_SSB_U;
    case LSB: return OmniRig::PM_SSB_L;
    case FSK: return OmniRig::PM_DIG_L;
    case FSK_R: return OmniRig::PM_DIG_U;
    case DIG_L: return OmniRig::PM_DIG_L;
    case DIG_U: return OmniRig::PM_DIG_U;
    case FM: return OmniRig::PM_FM;
    case DIG_FM: return OmniRig::PM_FM;
    default: break;
    }
  return OmniRig::PM_SSB_U;	// quieten compiler grumble
}

void OmniRigTransceiver::register_transceivers (TransceiverFactory::Transceivers * registry, int id1, int id2)
{
  (*registry)[OmniRig_transceiver_one_name] = TransceiverFactory::Capabilities {
    id1
    , TransceiverFactory::Capabilities::none // COM isn't serial or network
    , true				     // does PTT
    , false				     // doesn't select mic/data (use OmniRig config file)
    , true				     // can remote control RTS nd DTR
    , true				     // asynchronous interface
  };
  (*registry)[OmniRig_transceiver_two_name] = TransceiverFactory::Capabilities {
    id2
    , TransceiverFactory::Capabilities::none // COM isn't serial or network
    , true				     // does PTT
    , false				     // doesn't select mic/data (use OmniRig config file)
    , true				     // can remote control RTS nd DTR
    , true				     // asynchronous interface
  };
}

OmniRigTransceiver::OmniRigTransceiver (std::unique_ptr<TransceiverBase> wrapped, RigNumber n, TransceiverFactory::PTTMethod ptt_type, QString const& ptt_port)
  : wrapped_ {std::move (wrapped)}
  , use_for_ptt_ {TransceiverFactory::PTT_method_CAT == ptt_type || ("CAT" == ptt_port && (TransceiverFactory::PTT_method_RTS == ptt_type || TransceiverFactory::PTT_method_DTR == ptt_type))}
  , ptt_type_ {ptt_type}
  , startup_poll_countdown_ {2}
  , rig_number_ {n}
  , readable_params_ {0}
  , writable_params_ {0}
  , send_update_signal_ {false}
  , reversed_ {false}
  , starting_ {true}
{
}

OmniRigTransceiver::~OmniRigTransceiver ()
{
}

void OmniRigTransceiver::do_start ()
{
#if WSJT_TRACE_CAT
  qDebug () << "OmniRigTransceiver::do_start";
#endif

  wrapped_->start ();

  CoInitializeEx (nullptr, 0 /*COINIT_APARTMENTTHREADED*/); // required because Qt only does this for GUI thread

  omni_rig_.reset (new OmniRig::OmniRigX {this});
  if (omni_rig_->isNull ())
    {
#if WSJT_TRACE_CAT
      qDebug () << "OmniRigTransceiver::do_start: failed to start COM server";
#endif

      throw error {tr ("Failed to start OmniRig COM server")};
    }

  // COM/OLE exceptions get signalled
  connect (&*omni_rig_, SIGNAL (exception (int, QString, QString, QString)), this, SLOT (handle_COM_exception (int, QString, QString, QString)));

  // IOmniRigXEvent interface signals
  connect (&*omni_rig_, SIGNAL (VisibleChange ()), this, SLOT (handle_visible_change ()));
  connect (&*omni_rig_, SIGNAL (RigTypeChange (int)), this, SLOT (handle_rig_type_change (int)));
  connect (&*omni_rig_, SIGNAL (StatusChange (int)), this, SLOT (handle_status_change (int)));
  connect (&*omni_rig_, SIGNAL (ParamsChange (int, int)), this, SLOT (handle_params_change (int, int)));
  connect (&*omni_rig_
           , SIGNAL (CustomReply (int, QVariant const&, QVariant const&))
           , this, SLOT (handle_custom_reply (int, QVariant const&, QVariant const&)));

#if WSJT_TRACE_CAT
  qDebug ()
    << "OmniRig s/w version:" << QString::number (omni_rig_->SoftwareVersion ()).toLocal8Bit ()
    << "i/f version:" << QString::number (omni_rig_->InterfaceVersion ()).toLocal8Bit ()
    ;
#endif

  // fetch the interface of the RigX CoClass and instantiate a proxy object
  switch (rig_number_)
    {
    case One: rig_.reset (new OmniRig::RigX (omni_rig_->Rig1 ())); break;
    case Two: rig_.reset (new OmniRig::RigX (omni_rig_->Rig2 ())); break;
    }

  Q_ASSERT (rig_);
  Q_ASSERT (!rig_->isNull ());

  if (use_for_ptt_ && (TransceiverFactory::PTT_method_DTR == ptt_type_ || TransceiverFactory::PTT_method_RTS == ptt_type_))
    {
      // fetch the interface for the serial port if we need it for PTT
      port_.reset (new OmniRig::PortBits (rig_->PortBits ()));

      Q_ASSERT (port_);
      Q_ASSERT (!port_->isNull ());

      // if (!port_->Lock ()) // try to take exclusive use of the OmniRig serial port for PTT
      // 	{
      // 	  throw error {tr ("Failed to get exclusive use of %1" from OmniRig").arg (ptt_type)};
      // 	}

      // start off so we don't accidentally key the radio
      if (TransceiverFactory::PTT_method_DTR == ptt_type_)
        {
          port_->SetDtr (false);
        }
      else			// RTS
        {
          port_->SetRts (false);
        }
    }

  readable_params_ = rig_->ReadableParams ();
  writable_params_ = rig_->WriteableParams ();

#if WSJT_TRACE_CAT
  qDebug ()
    << QString ("OmniRig initial rig type: %1 readable params = 0x%2 writable params = 0x%3 for rig %4")
    .arg (rig_->RigType ())
    .arg (readable_params_, 8, 16, QChar ('0'))
    .arg (writable_params_, 8, 16, QChar ('0'))
    .arg (rig_number_).toLocal8Bit ()
    ;
#endif

  QTimer::singleShot (5000, this, SLOT (online_check ()));
}

void OmniRigTransceiver::do_stop ()
{
  if (port_)
    {
      // port_->Unlock ();		// release serial port
      port_->clear ();
    }

  rig_->clear ();

  omni_rig_->clear ();

  CoUninitialize ();

  wrapped_->stop ();

#if WSJT_TRACE_CAT
  qDebug () << "OmniRigTransceiver::do_stop";
#endif
}

void OmniRigTransceiver::online_check ()
{
  if (starting_)
    {
      if (--startup_poll_countdown_)
        {
          init_rig ();
          QTimer::singleShot (5000, this, SLOT (online_check ()));
        }
      else
        {
          startup_poll_countdown_ = 2;

          // signal that we haven't seen anything from OmniRig
          offline ("OmniRig initialisation timeout");
        }
    }
  else if (OmniRig::ST_ONLINE != rig_->Status ())
    {
      offline ("OmniRig rig went offline for more than 5 seconds");
    }
}

void OmniRigTransceiver::init_rig ()
{
  if (state ().split ())
    {
#if WSJT_TRACE_CAT
      qDebug () << "OmniRigTransceiver::init_rig: set split";
#endif

      rig_->SetSplitMode (state ().frequency (), state ().tx_frequency ());
    }
  else
    {
#if WSJT_TRACE_CAT
      qDebug () << "OmniRigTransceiver::init_rig: set simplex";
#endif

      rig_->SetSimplexMode (state ().frequency ());
    }
}

void OmniRigTransceiver::do_sync (bool force_signal)
{
  // nothing much we can do here, we just have to let OmniRig do its
  // stuff and its first poll should send us and update that will
  // trigger a update signal from us. Any attempt to query OmniRig
  // leads to a whole mess of trouble since its internal state is
  // garbage until it has done its first rig poll.
  send_update_signal_ = force_signal;
  update_complete ();
}

void OmniRigTransceiver::handle_COM_exception (int code, QString source, QString desc, QString help)
{
#if WSJT_TRACE_CAT
  qDebug () << "OmniRigTransceiver::handle_COM_exception:" << QString::number (code) + " at " + source + ": " + desc + " (" + help + ')';
#endif

  throw error {tr ("OmniRig COM/OLE error: %1 at %2: %3 (%4)").arg (QString::number (code)).arg (source). arg (desc). arg (help)};
}

void OmniRigTransceiver::handle_visible_change ()
{
#if WSJT_TRACE_CAT
  qDebug () << "OmniRig visibility change: visibility =" << omni_rig_->DialogVisible ();
#endif
}

void OmniRigTransceiver::handle_rig_type_change (int rig_number)
{
  if (rig_number_ == rig_number)
    {
      readable_params_ = rig_->ReadableParams ();
      writable_params_ = rig_->WriteableParams ();

#if WSJT_TRACE_CAT
      qDebug ()
        << QString ("OmniRig rig type change to: %1 readable params = 0x%2 writable params = 0x%3 for rig %4")
        .arg (rig_->RigType ())
        .arg (readable_params_, 8, 16, QChar ('0'))
        .arg (writable_params_, 8, 16, QChar ('0'))
        .arg (rig_number).toLocal8Bit ()
        ;
#endif

      offline ("OmniRig rig changed");
    }
}

void OmniRigTransceiver::handle_status_change (int rig_number)
{
  if (rig_number_ == rig_number)
    {
#if WSJT_TRACE_CAT
      qDebug ()
        << QString ("OmniRig status change: new status for rig %1 = ").arg (rig_number).toLocal8Bit () << rig_->StatusStr ().toLocal8Bit ();
#endif

      if (OmniRig::ST_ONLINE != rig_->Status ())
        {
          QTimer::singleShot (5000, this, SLOT (online_check ()));
        }
      else if (starting_)
        {
          starting_ = false;

          TransceiverState old_state {state ()};
          init_rig ();

          if (old_state != state () || send_update_signal_)
            {
              update_complete ();
              send_update_signal_ = false;
            }
        }
    }
}

void OmniRigTransceiver::handle_params_change (int rig_number, int params)
{
  if (rig_number_ == rig_number)
    {
#if WSJT_TRACE_CAT
      qDebug ()
        << QString ("OmniRig params change: params = 0x%1 for rig %2")
        .arg (params, 8, 16, QChar ('0'))
        .arg (rig_number).toLocal8Bit ()
        << "state before:" << state ()
        ;
#endif

      starting_ = false;

      TransceiverState old_state {state ()};
      auto need_frequency = false;

      // state_.online = true;	// sometimes we don't get an initial
      // 				// OmniRig::ST_ONLINE status change
      // 				// event

      if (params & OmniRig::PM_VFOAA)
        {
          update_split (false);
          reversed_ = false;
          update_rx_frequency (rig_->FreqA ());
          update_other_frequency (rig_->FreqB ());
        }
      if (params & OmniRig::PM_VFOAB)
        {
          update_split (true);
          reversed_ = false;
          update_rx_frequency (rig_->FreqA ());
          update_other_frequency (rig_->FreqB ());
        }
      if (params & OmniRig::PM_VFOBA)
        {
          update_split (true);
          reversed_ = true;
          update_other_frequency (rig_->FreqA ());
          update_rx_frequency (rig_->FreqB ());
        }
      if (params & OmniRig::PM_VFOBB)
        {
          update_split (false);
          reversed_ = true;
          update_other_frequency (rig_->FreqA ());
          update_rx_frequency (rig_->FreqB ());
        }
      if (params & OmniRig::PM_VFOA)
        {
          reversed_ = false;
          need_frequency = true;
        }
      if (params & OmniRig::PM_VFOB)
        {
          reversed_ = true;
          need_frequency = true;
        }

      if (params & OmniRig::PM_FREQ)
        {
          need_frequency = true;
        }
      if (params & OmniRig::PM_FREQA)
        {
          if (reversed_)
            {
              update_other_frequency (rig_->FreqA ());
            }
          else
            {
              update_rx_frequency (rig_->FreqA ());
            }
        }
      if (params & OmniRig::PM_FREQB)
        {
          if (reversed_)
            {
              update_rx_frequency (rig_->FreqB ());
            }
          else
            {
              update_other_frequency (rig_->FreqB ());
            }
        }

      if (need_frequency)
        {
          if (readable_params_ & OmniRig::PM_FREQA)
            {
              if (reversed_)
                {
                  update_other_frequency (rig_->FreqA ());
                }
              else
                {
                  update_rx_frequency (rig_->FreqA ());
                }
              need_frequency = false;
            }
          if (readable_params_ & OmniRig::PM_FREQB)
            {
              if (reversed_)
                {
                  update_rx_frequency (rig_->FreqB ());
                }
              else
                {
                  update_other_frequency (rig_->FreqB ());
                }
            }
        }
      if (need_frequency && (readable_params_ & OmniRig::PM_FREQ))
        {
          update_rx_frequency (rig_->Freq ());
        }

      if (params & OmniRig::PM_PITCH)
        {
        }
      if (params & OmniRig::PM_RITOFFSET)
        {
        }
      if (params & OmniRig::PM_RIT0)
        {
        }
      if (params & OmniRig::PM_VFOEQUAL)
        {
          auto f = readable_params_ & OmniRig::PM_FREQA ? rig_->FreqA () : rig_->Freq ();
          update_rx_frequency (f);
          update_other_frequency (f);
          update_mode (map_mode (rig_->Mode ()));
        }
      if (params & OmniRig::PM_VFOSWAP)
        {
          auto temp = state ().tx_frequency ();
          update_other_frequency (state ().frequency ());
          update_rx_frequency (temp);
          update_mode (map_mode (rig_->Mode ()));
        }
      if (params & OmniRig::PM_SPLITON)
        {
          update_split (true);
        }
      if (params & OmniRig::PM_SPLITOFF)
        {
          update_split (false);
        }
      if (params & OmniRig::PM_RITON)
        {
        }
      if (params & OmniRig::PM_RITOFF)
        {
        }
      if (params & OmniRig::PM_XITON)
        {
        }
      if (params & OmniRig::PM_XITOFF)
        {
        }
      if (params & OmniRig::PM_RX)
        {
          update_PTT (false);
        }
      if (params & OmniRig::PM_TX)
        {
          update_PTT ();
        }
      if (params & OmniRig::PM_CW_U)
        {
          update_mode (CW_R);
        }
      if (params & OmniRig::PM_CW_L)
        {
          update_mode (CW);
        }
      if (params & OmniRig::PM_SSB_U)
        {
          update_mode (USB);
        }
      if (params & OmniRig::PM_SSB_L)
        {
          update_mode (LSB);
        }
      if (params & OmniRig::PM_DIG_U)
        {
          update_mode (DIG_U);
        }
      if (params & OmniRig::PM_DIG_L)
        {
          update_mode (DIG_L);
        }
      if (params & OmniRig::PM_AM)
        {
          update_mode (AM);
        }
      if (params & OmniRig::PM_FM)
        {
          update_mode (FM);
        }

      if (old_state != state () || send_update_signal_)
        {
          update_complete ();
          send_update_signal_ = false;
        }

#if WSJT_TRACE_CAT
      qDebug ()
        << "OmniRig params change: state after:" << state ()
        ;
#endif
    }
}

void OmniRigTransceiver::handle_custom_reply (int rig_number, QVariant const& command, QVariant const& reply)
{
  (void)command;
  (void)reply;

  if (rig_number_ == rig_number)
    {
#if WSJT_TRACE_CAT
      qDebug ()
        << "OmniRig custom command" << command.toString ().toLocal8Bit ()
        << "with reply" << reply.toString ().toLocal8Bit ()
        << QString ("for rig %1").arg (rig_number).toLocal8Bit ()
        ;

      qDebug () << "OmniRig rig number:" << rig_number_ << ':' << state ();
#endif
    }
}

void OmniRigTransceiver::do_ptt (bool on)
{
#if WSJT_TRACE_CAT
  qDebug () << "OmniRigTransceiver::do_ptt:" << on << state ();
#endif

  if (use_for_ptt_ && TransceiverFactory::PTT_method_CAT == ptt_type_)
    {
#if WSJT_TRACE_CAT
      qDebug () << "OmniRigTransceiver::do_ptt: set PTT";
#endif

      rig_->SetTx (on ? OmniRig::PM_TX : OmniRig::PM_RX);
    }
  else
    {
      if (port_)
        {
          if (TransceiverFactory::PTT_method_RTS == ptt_type_)
            {
#if WSJT_TRACE_CAT
              qDebug () << "OmniRigTransceiver::do_ptt: set RTS";
#endif
              port_->SetRts (on);
            }
          else			// "DTR"
            {
#if WSJT_TRACE_CAT
              qDebug () << "OmniRigTransceiver::do_ptt: set DTR";
#endif

              port_->SetDtr (on);
            }
        }
      else
        {
#if WSJT_TRACE_CAT
          qDebug () << "OmniRigTransceiver::do_ptt: set PTT using basic transceiver";
#endif

          wrapped_->ptt (on);
        }

      if (state ().ptt () != on)
        {
          update_PTT (on);

          // no need for this as currently update_PTT() does it for us
          // update_complete ();
        }
    }
}

void OmniRigTransceiver::do_frequency (Frequency f)
{
#if WSJT_TRACE_CAT
  qDebug () << "OmniRigTransceiver::do_frequency:" << f << state ();
#endif

  if (OmniRig::PM_FREQ & writable_params_)
    {
      rig_->SetFreq (f);
      update_rx_frequency (f);
    }
  else if (reversed_ && (OmniRig::PM_FREQB & writable_params_))
    {
      rig_->SetFreqB (f);
      update_rx_frequency (f);
    }
  else if (!reversed_ && (OmniRig::PM_FREQA & writable_params_))
    {
      rig_->SetFreqA (f);
      update_rx_frequency (f);
    }
  else
    {
      throw error {tr ("OmniRig: don't know how to set rig frequency")};
    }
}

void OmniRigTransceiver::do_tx_frequency (Frequency tx, bool /* rationalise_mode */)
{
#if WSJT_TRACE_CAT
  qDebug () << "OmniRigTransceiver::do_tx_frequency:" << tx << state ();
#endif

  bool split {tx != 0};

  if (split)
    {
#if WSJT_TRACE_CAT
      qDebug () << "OmniRigTransceiver::do_tx_frequency: set SPLIT mode on";
#endif

      rig_->SetSplitMode (state ().frequency (), tx);
      update_other_frequency (tx);
      update_split (true);
    }
  else
    {
#if WSJT_TRACE_CAT
      qDebug () << "OmniRigTransceiver::do_tx_frequency: set SPLIT mode off";
#endif

      rig_->SetSimplexMode (state ().frequency ());
      update_split (false);
    }

  bool notify {false};

  if (readable_params_ & OmniRig::PM_FREQ || !(readable_params_ & (OmniRig::PM_FREQA | OmniRig::PM_FREQB)))
    {
      update_other_frequency (tx); // async updates won't return this
      // so just store it and hope
      // operator doesn't change the
      // "back" VFO on rig
      notify = true;
    }

  if (!((OmniRig::PM_VFOAB | OmniRig::PM_VFOBA | OmniRig::PM_SPLITON) & readable_params_))
    {
#if WSJT_TRACE_CAT
      qDebug () << "OmniRigTransceiver::do_tx_frequency: setting SPLIT manually";
#endif

      update_split (split);	// we can't read it so just set and
      // hope op doesn't change it
      notify = true;
    }

  if (notify)
    {
      update_complete ();
    }
}

void OmniRigTransceiver::do_mode (MODE mode, bool /* rationalise */)
{
#if WSJT_TRACE_CAT
  qDebug () << "OmniRigTransceiver::do_mode:" << mode << state ();
#endif

  // TODO: G4WJS OmniRig doesn't seem to have any capability of tracking/setting VFO B mode

  auto mapped = map_mode (mode);

  if (mapped & writable_params_)
    {
      rig_->SetMode (mapped);
      update_mode (mode);
    }
  else
    {
      offline ("OmniRig invalid mode");
    }
}
