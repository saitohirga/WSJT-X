#include "Transceiver.hpp"

#include "moc_Transceiver.cpp"

namespace
{
  struct init
  {
    init ()
    {
      qRegisterMetaType<Transceiver::TransceiverState> ("Transceiver::TransceiverState");
      qRegisterMetaType<Transceiver::MODE> ("Transceiver::MODE");
    }
  } static_initialization;
}

#if !defined (QT_NO_DEBUG_STREAM)

ENUM_QDEBUG_OPS_IMPL (Transceiver, MODE);

QDebug operator << (QDebug d, Transceiver::TransceiverState const& s)
{
  d.nospace ()
    << "Transceiver::TransceiverState(online: " << (s.online_ ? "yes" : "no")
    << " Frequency {" << s.frequency_[0] << "Hz, " << s.frequency_[1] << "Hz} " << s.mode_
    << "; SPLIT: " << (Transceiver::TransceiverState::on == s.split_ ? "on" : Transceiver::TransceiverState::off == s.split_ ? "off" : "unknown")
    << "; PTT: " << (s.ptt_ ? "on" : "off")
    << ')';
  return d.space (); 
}

#endif

ENUM_QDATASTREAM_OPS_IMPL (Transceiver, MODE);

ENUM_CONVERSION_OPS_IMPL (Transceiver, MODE);

bool operator != (Transceiver::TransceiverState const& lhs, Transceiver::TransceiverState const& rhs)
{
  return lhs.online_ != rhs.online_
    || lhs.frequency_[0] != rhs.frequency_[0]
    || lhs.frequency_[1] != rhs.frequency_[1]
    || lhs.mode_ != rhs.mode_
    || lhs.split_ != rhs.split_
    || lhs.ptt_ != rhs.ptt_;
}

bool operator == (Transceiver::TransceiverState const& lhs, Transceiver::TransceiverState const& rhs)
{
  return !(lhs != rhs);
}
