#include "HamlibTransceiver.hpp"

#include <cstring>

#include <QByteArray>
#include <QString>
#include <QDebug>

#include "moc_HamlibTransceiver.cpp"

namespace
{
  // Unfortunately bandwidth is conflated  with mode, this is probably
  // because Icom do  the same. So we have to  care about bandwidth if
  // we want  to set  mode otherwise we  will end up  setting unwanted
  // bandwidths every time we change mode.  The best we can do via the
  // Hamlib API is to request the  normal option for the mode and hope
  // that an appropriate filter is selected.  Also ensure that mode is
  // only set is absolutely necessary.  On Icoms (and probably others)
  // the filter is  selected by number without checking  the actual BW
  // so unless the  "normal" defaults are set on the  rig we won't get
  // desirable results.
  //
  // As  an ultimate  workaround make  sure  the user  always has  the
  // option to skip mode setting altogether.

  // reroute Hamlib diagnostic messages to Qt
  int debug_callback (enum rig_debug_level_e level, rig_ptr_t /* arg */, char const * format, va_list ap)
  {
    QString message;
    message = message.vsprintf (format, ap).trimmed ();

    switch (level)
      {
      case RIG_DEBUG_BUG:
        qFatal ("%s", message.toLocal8Bit ().data ());
        break;

      case RIG_DEBUG_ERR:
        qCritical ("%s", message.toLocal8Bit ().data ());
        break;

      case RIG_DEBUG_WARN:
        qWarning ("%s", message.toLocal8Bit ().data ());
        break;

      default:
        qDebug ("%s", message.toLocal8Bit ().data ());
        break;
      }

    return 0;
  }

  // callback function that receives transceiver capabilities from the
  // hamlib libraries
  int rigCallback (rig_caps const * caps, void * callback_data)
  {
    TransceiverFactory::Transceivers * rigs = reinterpret_cast<TransceiverFactory::Transceivers *> (callback_data);

    QString key;
    if ("Hamlib" == QString::fromLatin1 (caps->mfg_name).trimmed ()
        && "Dummy" == QString::fromLatin1 (caps->model_name).trimmed ())
      {
        key = TransceiverFactory::basic_transceiver_name_;
      }
    else
      {
        key = QString::fromLatin1 (caps->mfg_name).trimmed ()
          + ' '+ QString::fromLatin1 (caps->model_name).trimmed ()
          // + ' '+ QString::fromLatin1 (caps->version).trimmed ()
          // + " (" + QString::fromLatin1 (rig_strstatus (caps->status)).trimmed () + ')'
          ;
      }

    auto port_type = TransceiverFactory::Capabilities::none;
    switch (caps->port_type)
      {
      case RIG_PORT_SERIAL:
        port_type = TransceiverFactory::Capabilities::serial;
        break;

      case RIG_PORT_NETWORK:
        port_type = TransceiverFactory::Capabilities::network;
        break;

      default: break;
      }
    (*rigs)[key] = TransceiverFactory::Capabilities (caps->rig_model
                                                     , port_type
                                                     , RIG_PTT_RIG == caps->ptt_type || RIG_PTT_RIG_MICDATA == caps->ptt_type
                                                     , RIG_PTT_RIG_MICDATA == caps->ptt_type);

    return 1;			// keep them coming
  }

  // int frequency_change_callback (RIG * /* rig */, vfo_t vfo, freq_t f, rig_ptr_t arg)
  // {
  //   (void)vfo;			// unused in release build

  //   Q_ASSERT (vfo == RIG_VFO_CURR); // G4WJS: at the time of writing only current VFO is signalled by hamlib

  //   HamlibTransceiver * transceiver (reinterpret_cast<HamlibTransceiver *> (arg));
  //   Q_EMIT transceiver->frequency_change (f, Transceiver::A);
  //   return RIG_OK;
  // }

  class hamlib_tx_vfo_fixup final
  {
  public:
    hamlib_tx_vfo_fixup (RIG * rig, vfo_t tx_vfo)
      : rig_ {rig}
    {
      original_vfo_ = rig_->state.tx_vfo;
      rig_->state.tx_vfo = tx_vfo;
    }

    ~hamlib_tx_vfo_fixup ()
    {
      rig_->state.tx_vfo = original_vfo_;
    }

  private:
    RIG * rig_;
    vfo_t original_vfo_;
  };
}

void HamlibTransceiver::register_transceivers (TransceiverFactory::Transceivers * registry)
{
  rig_set_debug_callback (debug_callback, nullptr);

#if WSJT_HAMLIB_TRACE
  rig_set_debug (RIG_DEBUG_TRACE);
#elif defined (NDEBUG)
  rig_set_debug (RIG_DEBUG_ERR);
#else
  rig_set_debug (RIG_DEBUG_VERBOSE);
#endif

  rig_load_all_backends ();
  rig_list_foreach (rigCallback, registry);
}

void HamlibTransceiver::RIGDeleter::cleanup (RIG * rig)
{
  if (rig)
    {
      // rig->state.obj = 0;
      rig_cleanup (rig);
    }
}

HamlibTransceiver::HamlibTransceiver (int model_number
                                      , QString const& cat_port
                                      , int cat_baud
                                      , TransceiverFactory::DataBits cat_data_bits
                                      , TransceiverFactory::StopBits cat_stop_bits
                                      , TransceiverFactory::Handshake cat_handshake
                                      , bool cat_dtr_always_on
                                      , bool cat_rts_always_on
                                      , TransceiverFactory::PTTMethod ptt_type
                                      , TransceiverFactory::TXAudioSource back_ptt_port
                                      , QString const& ptt_port
                                      , int poll_interval)
  : PollingTransceiver {poll_interval}
  , rig_ {rig_init (model_number)}
  , back_ptt_port_ {TransceiverFactory::TX_audio_source_rear == back_ptt_port}
  , is_dummy_ {RIG_MODEL_DUMMY == model_number}
  , reversed_ {false}
  , split_query_works_ {true}
{
  if (!rig_)
    {
      throw error {tr ("Hamlib initialisation error")};
    }

  // rig_->state.obj = this;

  if (!cat_port.isEmpty ())
    {
      set_conf ("rig_pathname", cat_port.toLatin1 ().data ());
    }

  set_conf ("serial_speed", QByteArray::number (cat_baud).data ());
  set_conf ("data_bits", TransceiverFactory::seven_data_bits == cat_data_bits ? "7" : "8");
  set_conf ("stop_bits", TransceiverFactory::one_stop_bit == cat_stop_bits ? "1" : "2");

  switch (cat_handshake)
    {
    case TransceiverFactory::handshake_none: set_conf ("serial_handshake", "None"); break;
    case TransceiverFactory::handshake_XonXoff: set_conf ("serial_handshake", "XONXOFF"); break;
    case TransceiverFactory::handshake_hardware: set_conf ("serial_handshake", "Hardware"); break;
    }

  if (cat_dtr_always_on)
    {
      set_conf ("dtr_state", "ON");
    }
  if (TransceiverFactory::handshake_hardware != cat_handshake && cat_rts_always_on)
    {
      set_conf ("rts_state", "ON");
    }

  switch (ptt_type)
    {
    case TransceiverFactory::PTT_method_VOX:
      set_conf ("ptt_type", "None");
      break;

    case TransceiverFactory::PTT_method_CAT:
      // Use the default PTT_TYPE for the rig (defined in the Hamlib
      // rig back-end capabilities).
      break;

    case TransceiverFactory::PTT_method_DTR:
    case TransceiverFactory::PTT_method_RTS:
      if (!ptt_port.isEmpty () && ptt_port != "None" && ptt_port != cat_port)
        {
#if defined (WIN32)
          set_conf ("ptt_pathname", ("\\\\.\\" + ptt_port).toLatin1 ().data ());
#else
          set_conf ("ptt_pathname", ptt_port.toLatin1 ().data ());
#endif
        }

      if (TransceiverFactory::PTT_method_DTR == ptt_type)
        {
          set_conf ("ptt_type", "DTR");
        }
      else
        {
          set_conf ("ptt_type", "RTS");
        }
    }

  // Make Icom CAT split commands less glitchy
  set_conf ("no_xchg", "1");

  // would be nice to get events but not supported on Windows and also not on a lot of rigs
  // rig_set_freq_callback (rig_.data (), &frequency_change_callback, this);
}

HamlibTransceiver::~HamlibTransceiver ()
{
}

void HamlibTransceiver::error_check (int ret_code, QString const& doing) const
{
  if (RIG_OK != ret_code)
    {
#if WSJT_TRACE_CAT && WSJT_TRACE_CAT_POLLS
      qDebug () << "HamlibTransceiver::error_check: error:" << rigerror (ret_code);
#endif

      throw error {tr ("Hamlib error: %1 while %2").arg (rigerror (ret_code)).arg (doing)};
    }
}

void HamlibTransceiver::do_start ()
{
#if WSJT_TRACE_CAT
  qDebug () << "HamlibTransceiver::do_start rig:" << QString::fromLatin1 (rig_->caps->mfg_name).trimmed () + ' '
    + QString::fromLatin1 (rig_->caps->model_name).trimmed ();
#endif

  error_check (rig_open (rig_.data ()), tr ("opening connection to rig"));

  if (!is_dummy_)
    {
      freq_t f1;
      freq_t f2;
      rmode_t m {RIG_MODE_USB};
      rmode_t mb;
      pbwidth_t w {rig_passband_wide (rig_.data (), m)};
      pbwidth_t wb;
      if (!rig_->caps->get_vfo && (rig_->caps->set_vfo || rig_has_vfo_op (rig_.data (), RIG_OP_TOGGLE)))
        {
          // Icom have deficient CAT protocol with no way of reading which
          // VFO is selected or if SPLIT is selected so we have to simply
          // assume it is as when we started by setting at open time right
          // here. We also gather/set other initial state.
#if WSJT_TRACE_CAT
          qDebug () << "HamlibTransceiver::init_rig rig_get_freq";
#endif
          error_check (rig_get_freq (rig_.data (), RIG_VFO_CURR, &f1), tr ("getting current frequency"));
#if WSJT_TRACE_CAT
          qDebug () << "HamlibTransceiver::init_rig rig_get_freq current frequency =" << f1;
#endif

#if WSJT_TRACE_CAT
          qDebug () << "HamlibTransceiver::init_rig rig_get_mode current mode";
#endif
          error_check (rig_get_mode (rig_.data (), RIG_VFO_CURR, &m, &w), tr ("getting current mode"));
#if WSJT_TRACE_CAT
          qDebug () << "HamlibTransceiver::init_rig rig_get_mode current mode =" << rig_strrmode (m) << "bw =" << w;
#endif

          if (!rig_->caps->set_vfo)
            {
#if WSJT_TRACE_CAT
              qDebug () << "HamlibTransceiver::init_rig rig_vfo_op TOGGLE";
#endif
              error_check (rig_vfo_op (rig_.data (), RIG_VFO_CURR, RIG_OP_TOGGLE), tr ("exchanging VFOs"));
            }
          else
            {
#if WSJT_TRACE_CAT
              qDebug () << "HamlibTransceiver::init_rig rig_set_vfo to other VFO";
#endif
              error_check (rig_set_vfo (rig_.data (), rig_->state.vfo_list & RIG_VFO_B ? RIG_VFO_B : RIG_VFO_SUB), tr ("setting current VFO"));
            }

#if WSJT_TRACE_CAT
          qDebug () << "HamlibTransceiver::init_rig rig_get_freq other frequency";
#endif
          error_check (rig_get_freq (rig_.data (), RIG_VFO_CURR, &f2), tr ("getting other VFO frequency"));
#if WSJT_TRACE_CAT
          qDebug () << "HamlibTransceiver::init_rig rig_get_freq other frequency =" << f2;
#endif

#if WSJT_TRACE_CAT
          qDebug () << "HamlibTransceiver::init_rig rig_get_mode other VFO";
#endif
          error_check (rig_get_mode (rig_.data (), RIG_VFO_CURR, &mb, &wb), tr ("getting other VFO mode"));
#if WSJT_TRACE_CAT
          qDebug () << "HamlibTransceiver::init_rig rig_get_mode other mode =" << rig_strrmode (mb) << "bw =" << wb;
#endif

          update_other_frequency (f2);

          if (!rig_->caps->set_vfo)
            {
#if WSJT_TRACE_CAT
              qDebug () << "HamlibTransceiver::init_rig rig_vfo_op TOGGLE";
#endif
              error_check (rig_vfo_op (rig_.data (), RIG_VFO_CURR, RIG_OP_TOGGLE), tr ("exchanging VFOs"));
            }
          else
            {
#if WSJT_TRACE_CAT
              qDebug () << "HamlibTransceiver::init_rig rig_set_vfo A/MAIN";
#endif
              error_check (rig_set_vfo (rig_.data (), rig_->state.vfo_list & RIG_VFO_A ? RIG_VFO_A : RIG_VFO_MAIN), tr ("setting current VFO"));
            }

          if (f1 != f2 || m != mb || w != wb)	// we must have started with MAIN/A
            {
              update_rx_frequency (f1);
            }
          else
            {
#if WSJT_TRACE_CAT
              qDebug () << "HamlibTransceiver::init_rig rig_get_freq";
#endif
              error_check (rig_get_freq (rig_.data (), RIG_VFO_CURR, &f1), tr ("getting frequency"));
#if WSJT_TRACE_CAT
              qDebug () << "HamlibTransceiver::init_rig rig_get_freq frequency =" << f1;
#endif

#if WSJT_TRACE_CAT
              qDebug () << "HamlibTransceiver::init_rig rig_get_mode";
#endif
              error_check (rig_get_mode (rig_.data (), RIG_VFO_CURR, &m, &w), tr ("getting mode"));
#if WSJT_TRACE_CAT
              qDebug () << "HamlibTransceiver::init_rig rig_get_mode mode =" << rig_strrmode (m) << "bw =" << w;
#endif

              update_rx_frequency (f1);
            }

#if WSJT_TRACE_CAT
          // qDebug () << "HamlibTransceiver::init_rig rig_set_split_vfo split off";
#endif
          // error_check (rig_set_split_vfo (rig_.data (), RIG_VFO_CURR, RIG_SPLIT_OFF, RIG_VFO_CURR), tr ("setting split off"));
          // update_split (false);
        }
      else
        {
          vfo_t v {RIG_VFO_A};  // assume RX always on VFO A/MAIN

          if (rig_->caps->get_vfo)
            {
#if WSJT_TRACE_CAT
              qDebug () << "HamlibTransceiver::init_rig rig_get_vfo current VFO";
#endif
              error_check (rig_get_vfo (rig_.data (), &v), tr ("getting current VFO")); // has side effect of establishing current VFO inside hamlib
#if WSJT_TRACE_CAT
              qDebug () << "HamlibTransceiver::init_rig rig_get_vfo current VFO = " << rig_strvfo (v);
#endif
            }

          reversed_ = RIG_VFO_B == v;

          if (!(rig_->caps->targetable_vfo & (RIG_TARGETABLE_MODE | RIG_TARGETABLE_PURE)))
            {
#if WSJT_TRACE_CAT
              qDebug () << "HamlibTransceiver::init_rig rig_get_mode current mode";
#endif
              error_check (rig_get_mode (rig_.data (), RIG_VFO_CURR, &m, &w), tr ("getting current mode"));
#if WSJT_TRACE_CAT
              qDebug () << "HamlibTransceiver::init_rig rig_get_mode current mode =" << rig_strrmode (m) << "bw =" << w;
#endif
            }
        }
      update_mode (map_mode (m));
    }

  poll ();

#if WSJT_TRACE_CAT
  qDebug () << "HamlibTransceiver::init_rig exit" << state () << "reversed =" << reversed_;
#endif
}

void HamlibTransceiver::do_stop ()
{
  if (rig_)
    {
      rig_close (rig_.data ());
    }

#if WSJT_TRACE_CAT
  qDebug () << "HamlibTransceiver::do_stop: state:" << state () << "reversed =" << reversed_;
#endif
}

auto HamlibTransceiver::get_vfos () const -> std::tuple<vfo_t, vfo_t>
{
  if (rig_->caps->get_vfo)
    {
      vfo_t v;
#if WSJT_TRACE_CAT
      qDebug () << "HamlibTransceiver::get_vfos rig_get_vfo";
#endif
      error_check (rig_get_vfo (rig_.data (), &v), tr ("getting current VFO")); // has side effect of establishing current VFO inside hamlib
#if WSJT_TRACE_CAT
      qDebug () << "HamlibTransceiver::get_vfos rig_get_vfo VFO = " << rig_strvfo (v);
#endif

      reversed_ = RIG_VFO_B == v;
    }
  else if (rig_->caps->set_vfo)
    {
      // use VFO A/MAIN for main frequency and B/SUB for Tx
      // frequency if split since these type of radios can only
      // support this way around

#if WSJT_TRACE_CAT
      qDebug () << "HamlibTransceiver::get_vfos rig_set_vfo VFO = A/MAIN";
#endif
      error_check (rig_set_vfo (rig_.data (), rig_->state.vfo_list & RIG_VFO_A ? RIG_VFO_A : RIG_VFO_MAIN), tr ("setting current VFO"));
    }
  // else only toggle available but both VFOs should be substitutable 

  auto rx_vfo = rig_->state.vfo_list & RIG_VFO_A ? RIG_VFO_A : RIG_VFO_MAIN;
  auto tx_vfo = state ().split () ? (rig_->state.vfo_list & RIG_VFO_B ? RIG_VFO_B : RIG_VFO_SUB) : rx_vfo;
  if (reversed_)
    {
#if WSJT_TRACE_CAT
      qDebug () << "HamlibTransceiver::get_vfos reversing VFOs";
#endif
      std::swap (rx_vfo, tx_vfo);
    }

#if WSJT_TRACE_CAT
  qDebug () << "HamlibTransceiver::get_vfos RX VFO = " << rig_strvfo (rx_vfo) << " TX VFO = " << rig_strvfo (tx_vfo);
#endif

  return std::make_tuple (rx_vfo, tx_vfo);
}

void HamlibTransceiver::do_frequency (Frequency f, MODE m)
{
#if WSJT_TRACE_CAT
  qDebug () << "HamlibTransceiver::do_frequency:" << f << "mode:" << m << "reversed:" << reversed_;
#endif

  if (UNK != m)
    {
      do_mode (m, false);
    }

  if (!is_dummy_)
    {
      error_check (rig_set_freq (rig_.data (), RIG_VFO_CURR, f), tr ("setting frequency"));
    }

  update_rx_frequency (f);
}

void HamlibTransceiver::do_tx_frequency (Frequency tx, bool rationalise_mode)
{
#if WSJT_TRACE_CAT
  qDebug () << "HamlibTransceiver::do_tx_frequency:" << tx << "rationalise mode:" << rationalise_mode << "reversed:" << reversed_;
#endif

  if (!is_dummy_)
    {
      auto split = tx ? RIG_SPLIT_ON : RIG_SPLIT_OFF;
      update_split (tx);
      auto vfos = get_vfos ();
      // auto rx_vfo = std::get<0> (vfos); // or use RIG_VFO_CURR
      auto tx_vfo = std::get<1> (vfos);

      if (tx)
        {
          // Doing set split for the 1st of two times, this one
          // ensures that the internal Hamlib state is correct
          // otherwise rig_set_split_freq() will target the wrong VFO
          // on some rigs
#if WSJT_TRACE_CAT
          qDebug () << "HamlibTransceiver::do_tx_frequency rig_set_split_vfo split =" << split;
#endif
          auto rc = rig_set_split_vfo (rig_.data (), RIG_VFO_CURR, split, tx_vfo);
          if (tx || (-RIG_ENAVAIL != rc && -RIG_ENIMPL != rc))
            {
              // On rigs that can't have split controlled only throw an
              // exception when an error other than command not accepted
              // is returned when trying to leave split mode. This allows
              // fake split mode and non-split mode to work without error
              // on such rigs without having to know anything about the
              // specific rig.
              error_check (rc, tr ("setting/unsetting split mode"));
            }

#if WSJT_TRACE_CAT
          qDebug () << "HamlibTransceiver::do_tx_frequency rig_set_split_freq";
#endif

          hamlib_tx_vfo_fixup fixup (rig_.data (), tx_vfo);
          error_check (rig_set_split_freq (rig_.data (), RIG_VFO_CURR, tx), tr ("setting split TX frequency"));

          if (rationalise_mode)
            {
              rmode_t current_mode;
              pbwidth_t current_width;

#if WSJT_TRACE_CAT
              qDebug () << "HamlibTransceiver::do_tx_frequency rig_get_split_mode";
#endif
              error_check (rig_get_split_mode (rig_.data (), RIG_VFO_CURR, &current_mode, &current_width), tr ("getting mode of split TX VFO"));
#if WSJT_TRACE_CAT
              qDebug () << "HamlibTransceiver::do_tx_frequency rig_get_split_mode mode = " << rig_strrmode (current_mode) << "bw =" << current_width;
#endif

              auto new_mode = map_mode (state ().mode ());
              if (new_mode != current_mode)
                {
#if WSJT_TRACE_CAT
                  qDebug () << "HamlibTransceiver::do_tx_frequency rig_set_split_mode mode = " << rig_strrmode (new_mode);
#endif
                  error_check (rig_set_split_mode (rig_.data (), RIG_VFO_CURR, new_mode, rig_passband_wide (rig_.data (), new_mode)), tr ("setting split TX VFO mode"));
                }
            }
        }

      // enable split last since some rigs (Kenwood for one) come out
      // of split when you switch RX VFO (to set split mode above for
      // example)

#if WSJT_TRACE_CAT
      qDebug () << "HamlibTransceiver::do_tx_frequency rig_set_split_vfo split =" << split;
#endif
      auto rc = rig_set_split_vfo (rig_.data (), RIG_VFO_CURR, split, tx_vfo);
      if (tx || (-RIG_ENAVAIL != rc && -RIG_ENIMPL != rc))
        {
          // On rigs that can't have split controlled only throw an
          // exception when an error other than command not accepted
          // is returned when trying to leave split mode. This allows
          // fake split mode and non-split mode to work without error
          // on such rigs without having to know anything about the
          // specific rig.
          error_check (rc, tr ("setting/unsetting split mode"));
        }
    }

  update_other_frequency (tx);
}

void HamlibTransceiver::do_mode (MODE mode, bool rationalise)
{
#if WSJT_TRACE_CAT
  qDebug () << "HamlibTransceiver::do_mode:" << mode << "rationalise:" << rationalise;
#endif

  if (!is_dummy_)
    {
      auto vfos = get_vfos ();
      // auto rx_vfo = std::get<0> (vfos);
      auto tx_vfo = std::get<1> (vfos);

      rmode_t current_mode;
      pbwidth_t current_width;

#if WSJT_TRACE_CAT
      qDebug () << "HamlibTransceiver::do_mode rig_get_mode";
#endif
      error_check (rig_get_mode (rig_.data (), RIG_VFO_CURR, &current_mode, &current_width), tr ("getting current VFO mode"));
#if WSJT_TRACE_CAT
      qDebug () << "HamlibTransceiver::do_mode rig_get_mode mode = " << rig_strrmode (current_mode) << "bw =" << current_width;
#endif

      auto new_mode = map_mode (mode);
      if (new_mode != current_mode)
        {
#if WSJT_TRACE_CAT
          qDebug () << "HamlibTransceiver::do_mode rig_set_mode mode = " << rig_strrmode (new_mode);
#endif
          error_check (rig_set_mode (rig_.data (), RIG_VFO_CURR, new_mode, rig_passband_wide (rig_.data (), new_mode)), tr ("setting current VFO mode"));
        }
      
      if (state ().split () && rationalise)
        {
#if WSJT_TRACE_CAT
          qDebug () << "HamlibTransceiver::do_mode rig_get_split_mode";
#endif
          error_check (rig_get_split_mode (rig_.data (), RIG_VFO_CURR, &current_mode, &current_width), tr ("getting split TX VFO mode"));
#if WSJT_TRACE_CAT
          qDebug () << "HamlibTransceiver::do_mode rig_get_split_mode mode = " << rig_strrmode (current_mode) << "bw =" << current_width;
#endif

          if (new_mode != current_mode)
            {
#if WSJT_TRACE_CAT
              qDebug () << "HamlibTransceiver::do_mode rig_set_split_mode mode = " << rig_strrmode (new_mode);
#endif
              hamlib_tx_vfo_fixup fixup (rig_.data (), tx_vfo);
              error_check (rig_set_split_mode (rig_.data (), RIG_VFO_CURR, new_mode, rig_passband_wide (rig_.data (), new_mode)), tr ("setting split TX VFO mode"));
            }
        }
    }

  update_mode (mode);
}

void HamlibTransceiver::poll ()
{
  if (is_dummy_)
    {
      // split with dummy is never reported since there is no rig
      if (state ().split ())
        {
          update_split (false);
        }
    }
  else
    {
#if !WSJT_TRACE_CAT_POLLS
#if defined (NDEBUG)
      rig_set_debug (RIG_DEBUG_ERR);
#else
      rig_set_debug (RIG_DEBUG_VERBOSE);
#endif
#endif

      freq_t f;
      rmode_t m;
      pbwidth_t w;
      split_t s;

      if (rig_->caps->get_vfo)
        {
#if WSJT_TRACE_CAT && WSJT_TRACE_CAT_POLLS
          qDebug () << "HamlibTransceiver::poll rig_get_vfo";
#endif
          vfo_t v;
          error_check (rig_get_vfo (rig_.data (), &v), tr ("getting current VFO")); // has side effect of establishing current VFO inside hamlib
#if WSJT_TRACE_CAT && WSJT_TRACE_CAT_POLLS
          qDebug () << "HamlibTransceiver::poll rig_get_vfo VFO = " << rig_strvfo (v);
#endif

          reversed_ = RIG_VFO_B == v;
        }

#if WSJT_TRACE_CAT && WSJT_TRACE_CAT_POLLS
      qDebug () << "HamlibTransceiver::poll rig_get_freq";
#endif
      error_check (rig_get_freq (rig_.data (), RIG_VFO_CURR, &f), tr ("getting current VFO frequency"));
#if WSJT_TRACE_CAT && WSJT_TRACE_CAT_POLLS
      qDebug () << "HamlibTransceiver::poll rig_get_freq frequency =" << f;
#endif

      update_rx_frequency (f);

      if (state ().split () && (rig_->caps->targetable_vfo & (RIG_TARGETABLE_FREQ | RIG_TARGETABLE_PURE)))
        {
          // only read "other" VFO if in split, this allows rigs like
          // FlexRadio to work in Kenwood TS-2000 mode despite them
          // not having a FB; command

          // we can only probe current VFO unless rig supports reading
          // the other one directly because we can't glitch the Rx
#if WSJT_TRACE_CAT && WSJT_TRACE_CAT_POLLS
          qDebug () << "HamlibTransceiver::poll rig_get_freq other VFO";
#endif
          error_check (rig_get_freq (rig_.data ()
                                     , reversed_
                                     ? (rig_->state.vfo_list & RIG_VFO_A ? RIG_VFO_A : RIG_VFO_MAIN)
                                     : (rig_->state.vfo_list & RIG_VFO_B ? RIG_VFO_B : RIG_VFO_SUB)
                                     , &f), tr ("getting current VFO frequency"));
#if WSJT_TRACE_CAT && WSJT_TRACE_CAT_POLLS
          qDebug () << "HamlibTransceiver::poll rig_get_freq other VFO =" << f;
#endif

          update_other_frequency (f);
        }

#if WSJT_TRACE_CAT && WSJT_TRACE_CAT_POLLS
      qDebug () << "HamlibTransceiver::poll rig_get_mode";
#endif
      error_check (rig_get_mode (rig_.data (), RIG_VFO_CURR, &m, &w), tr ("getting current VFO mode"));
#if WSJT_TRACE_CAT && WSJT_TRACE_CAT_POLLS
      qDebug () << "HamlibTransceiver::poll rig_get_mode mode =" << rig_strrmode (m) << "bw =" << w;
#endif

      update_mode (map_mode (m));

      if (rig_->caps->get_split_vfo && split_query_works_)
        {
#if WSJT_TRACE_CAT && WSJT_TRACE_CAT_POLLS
          qDebug () << "HamlibTransceiver::poll rig_get_split_vfo";
#endif
          vfo_t v {RIG_VFO_NONE};		// so we can tell if it doesn't get updated :(
          auto rc = rig_get_split_vfo (rig_.data (), RIG_VFO_CURR, &s, &v);
          if (-RIG_OK == rc && RIG_SPLIT_ON == s)
            {
#if WSJT_TRACE_CAT && WSJT_TRACE_CAT_POLLS
              qDebug () << "HamlibTransceiver::poll rig_get_split_vfo split = " << s << " VFO = " << rig_strvfo (v);
#endif

              update_split (true);
              // if (RIG_VFO_A == v)
              // 	{
              // 	  reversed_ = true;	// not sure if this helps us here
              // 	}
            }
          else if (-RIG_OK == rc)	// not split
            {
#if WSJT_TRACE_CAT && WSJT_TRACE_CAT_POLLS
              qDebug () << "HamlibTransceiver::poll rig_get_split_vfo split = " << s << " VFO = " << rig_strvfo (v);
#endif

              update_split (false);
            }
          else if (-RIG_ENAVAIL == rc || -RIG_ENIMPL == rc) // Some rigs (Icom) don't have a way of reporting SPLIT mode
            {
#if WSJT_TRACE_CAT && WSJT_TRACE_CAT_POLLS
              qDebug () << "HamlibTransceiver::poll rig_get_split_vfo can't do on this rig";
#endif

              // just report how we see it based on prior commands
              split_query_works_ = false;
            }
          else
            {
              error_check (rc, tr ("getting split TX VFO"));
            }
        }

      if (RIG_PTT_NONE != rig_->state.pttport.type.ptt && rig_->caps->get_ptt)
        {
#if WSJT_TRACE_CAT && WSJT_TRACE_CAT_POLLS
          qDebug () << "HamlibTransceiver::poll rig_get_ptt";
#endif
          ptt_t p;
          auto rc = rig_get_ptt (rig_.data (), RIG_VFO_CURR, &p);
          if (-RIG_ENAVAIL != rc && -RIG_ENIMPL != rc) // may fail if
                                // Net rig ctl and target doesn't
                                // support command
            {
              error_check (rc, tr ("getting PTT state"));
#if WSJT_TRACE_CAT && WSJT_TRACE_CAT_POLLS
              qDebug () << "HamlibTransceiver::poll rig_get_ptt PTT =" << p;
#endif

              update_PTT (!(RIG_PTT_OFF == p));
            }
        }

#if !WSJT_TRACE_CAT_POLLS
#if WSJT_HAMLIB_TRACE
      rig_set_debug (RIG_DEBUG_TRACE);
#elif defined (NDEBUG)
      rig_set_debug (RIG_DEBUG_ERR);
#else
      rig_set_debug (RIG_DEBUG_VERBOSE);
#endif
#endif
    }
}

void HamlibTransceiver::do_ptt (bool on)
{
#if WSJT_TRACE_CAT
  qDebug () << "HamlibTransceiver::do_ptt:" << on << state () << "reversed =" << reversed_;
#endif

  if (on)
    {
      if (RIG_PTT_NONE != rig_->state.pttport.type.ptt)
        {
#if WSJT_TRACE_CAT
          qDebug () << "HamlibTransceiver::do_ptt rig_set_ptt PTT = true";
#endif
          error_check (rig_set_ptt (rig_.data (), RIG_VFO_CURR, back_ptt_port_ ? RIG_PTT_ON_DATA : RIG_PTT_ON), tr ("setting PTT on"));
        }
    }
  else
    {
      if (RIG_PTT_NONE != rig_->state.pttport.type.ptt)
        {
#if WSJT_TRACE_CAT
          qDebug () << "HamlibTransceiver::do_ptt rig_set_ptt PTT = false";
#endif
          error_check (rig_set_ptt (rig_.data (), RIG_VFO_CURR, RIG_PTT_OFF), tr ("setting PTT off"));
        }
    }

  update_PTT (on);
}

void HamlibTransceiver::set_conf (char const * item, char const * value)
{
  token_t token = rig_token_lookup (rig_.data (), item);
  if (RIG_CONF_END != token)	// only set if valid for rig model
    {
      error_check (rig_set_conf (rig_.data (), token, value), tr ("setting a configuration item"));
    }
}

QByteArray HamlibTransceiver::get_conf (char const * item)
{
  token_t token = rig_token_lookup (rig_.data (), item);
  QByteArray value {128, '\0'};
  if (RIG_CONF_END != token)	// only get if valid for rig model
    {
      error_check (rig_get_conf (rig_.data (), token, value.data ()), tr ("getting a configuration item"));
    }
  return value;
}

auto HamlibTransceiver::map_mode (rmode_t m) const -> MODE
{
  switch (m)
    {
    case RIG_MODE_AM:
    case RIG_MODE_SAM:
    case RIG_MODE_AMS:
    case RIG_MODE_DSB:
      return AM;

    case RIG_MODE_CW:
      return CW;

    case RIG_MODE_CWR:
      return CW_R;

    case RIG_MODE_USB:
    case RIG_MODE_ECSSUSB:
    case RIG_MODE_SAH:
    case RIG_MODE_FAX:
      return USB;

    case RIG_MODE_LSB:
    case RIG_MODE_ECSSLSB:
    case RIG_MODE_SAL:
      return LSB;

    case RIG_MODE_RTTY:
      return FSK;

    case RIG_MODE_RTTYR:
      return FSK_R;

    case RIG_MODE_PKTLSB:
      return DIG_L;

    case RIG_MODE_PKTUSB:
      return DIG_U;

    case RIG_MODE_FM:
    case RIG_MODE_WFM:
      return FM;

    case RIG_MODE_PKTFM:
      return DIG_FM;

    default:
      return UNK;
    }
}

rmode_t HamlibTransceiver::map_mode (MODE mode) const
{
  switch (mode)
    {
    case AM: return RIG_MODE_AM;
    case CW: return RIG_MODE_CW;
    case CW_R: return RIG_MODE_CWR;
    case USB: return RIG_MODE_USB;
    case LSB: return RIG_MODE_LSB;
    case FSK: return RIG_MODE_RTTY;
    case FSK_R: return RIG_MODE_RTTYR;
    case DIG_L: return RIG_MODE_PKTLSB;
    case DIG_U: return RIG_MODE_PKTUSB;
    case FM: return RIG_MODE_FM;
    case DIG_FM: return RIG_MODE_PKTFM;
    default: break;
    }
  return RIG_MODE_USB;	// quieten compiler grumble
}
