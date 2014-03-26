#include "DXLabSuiteCommanderTransceiver.hpp"

#include <QTcpSocket>
#include <QRegularExpression>

#include "NetworkServerLookup.hpp"

namespace
{
  char const * const commander_transceiver_name {"DX Lab Suite Commander"};
  int socket_wait_time {5000};

  QString map_mode (Transceiver::MODE mode)
  {
    switch (mode)
      {
      case Transceiver::AM: return "AM";
      case Transceiver::CW: return "CW";
      case Transceiver::CW_R: return "CW-R";
      case Transceiver::USB: return "USB";
      case Transceiver::LSB: return "LSB";
      case Transceiver::FSK: return "RTTY";
      case Transceiver::FSK_R: return "RTTY-R";
      case Transceiver::DIG_L: return "DATA-L";
      case Transceiver::DIG_U: return "DATA-U";
      case Transceiver::FM:
      case Transceiver::DIG_FM:
	return "FM";
      default: break;
      }
    return "USB";
  }
}

void DXLabSuiteCommanderTransceiver::register_transceivers (TransceiverFactory::Transceivers * registry, int id)
{
  (*registry)[commander_transceiver_name] = TransceiverFactory::Capabilities {id, TransceiverFactory::Capabilities::network, true};
}

DXLabSuiteCommanderTransceiver::DXLabSuiteCommanderTransceiver (std::unique_ptr<TransceiverBase> wrapped, QString const& address, bool use_for_ptt, int poll_interval)
  : PollingTransceiver {poll_interval}
  , wrapped_ {std::move (wrapped)}
  , use_for_ptt_ {use_for_ptt}
  , server_ {address}
  , commander_ {nullptr}
{
}

DXLabSuiteCommanderTransceiver::~DXLabSuiteCommanderTransceiver ()
{
}

void DXLabSuiteCommanderTransceiver::do_start ()
{
#if WSJT_TRACE_CAT
  qDebug () << "DXLabSuiteCommanderTransceiver::start";
#endif

  wrapped_->start ();

  auto server_details = network_server_lookup (server_, 52002u, QHostAddress::LocalHost, QAbstractSocket::IPv4Protocol);

  if (!commander_)
    {
      commander_ = new QTcpSocket {this}; // QObject takes ownership
    }

  commander_->connectToHost (std::get<0> (server_details), std::get<1> (server_details));
  if (!commander_->waitForConnected (socket_wait_time))
    {
#if WSJT_TRACE_CAT
      qDebug () << "DXLabSuiteCommanderTransceiver::start failed to connect" << commander_->errorString ();
#endif

      throw error {"Failed to connect to DX Lab Suite Commander\n" + commander_->errorString ().toLocal8Bit ()};
    }
      
  poll ();
}

void DXLabSuiteCommanderTransceiver::do_stop ()
{
  if (commander_)
    {
      commander_->close ();
      delete commander_, commander_ = nullptr;
    }

  wrapped_->stop ();

#if WSJT_TRACE_CAT
  qDebug () << "DXLabSuiteCommanderTransceiver::stop";
#endif
}

void DXLabSuiteCommanderTransceiver::do_ptt (bool on)
{
#if WSJT_TRACE_CAT
  qDebug () << "DXLabSuiteCommanderTransceiver::do_ptt:" << on << state ();
#endif

  if (use_for_ptt_)
    {
      send_command (on  ? "<command:5>CmdTX<parameters:0>" : "<command:5>CmdRX<parameters:0>");
    }
  else
    {
      wrapped_->ptt (on);
    }

  update_PTT (on);
}

void DXLabSuiteCommanderTransceiver::do_frequency (Frequency f)
{
#if WSJT_TRACE_CAT
  qDebug () << "DXLabSuiteCommanderTransceiver::do_frequency:" << f << state ();
#endif

  // number is localised
  // avoid floating point translation errors by adding a small number (0.1Hz)
  send_command ("<command:10>CmdSetFreq<parameters:23><xcvrfreq:10>" + QString ("%L1").arg (f / 1e3 + 1e-4, 10, 'f', 3).toLocal8Bit ());
  update_rx_frequency (f);
}

void DXLabSuiteCommanderTransceiver::do_tx_frequency (Frequency tx, bool /* rationalise_mode */)
{
#if WSJT_TRACE_CAT
  qDebug () << "DXLabSuiteCommanderTransceiver::do_tx_frequency:" << tx << state ();
#endif

  if (tx)
    {
      send_command ("<command:8>CmdSplit<parameters:7><1:2>on");
      update_split (true);

      // number is localised
      // avoid floating point translation errors by adding a small number (0.1Hz)

      // set TX frequency after going split because going split
      // rationalises TX VFO mode and that can change the frequency on
      // Yaesu rigs if CW is involved
      send_command ("<command:12>CmdSetTxFreq<parameters:23><xcvrfreq:10>" + QString ("%L1").arg (tx / 1e3 + 1e-4, 10, 'f', 3).toLocal8Bit ());
    }
  else
    {
      send_command ("<command:8>CmdSplit<parameters:8><1:3>off");
    }
  update_other_frequency (tx);
}

void DXLabSuiteCommanderTransceiver::do_mode (MODE mode, bool /* rationalise */)
{
#if WSJT_TRACE_CAT
  qDebug () << "DXLabSuiteCommanderTransceiver::do_mode:" << mode << state ();
#endif

  auto mapped = map_mode (mode);
  send_command ((QString ("<command:10>CmdSetMode<parameters:%1><1:%2>").arg (5 + mapped.size ()).arg (mapped.size ()) + mapped).toLocal8Bit ());

  if (state ().split ())
    {
      // this toggle ensures that the TX VFO mode is the same as the RX VFO
      send_command ("<command:8>CmdSplit<parameters:8><1:3>off");
      send_command ("<command:8>CmdSplit<parameters:7><1:2>on");
    }

  // setting TX frequency rationalises the mode on Icoms so get current and set
  poll ();
}

void DXLabSuiteCommanderTransceiver::poll ()
{
#if WSJT_TRACE_CAT && WSJT_TRACE_CAT_POLLS
  bool quiet {false};
#else
  bool quiet {true};
#endif

  send_command ("<command:11>CmdSendFreq<parameters:0>", quiet);
  auto reply = read_reply (quiet);
  if (0 == reply.indexOf ("<CmdFreq:"))
    {
      // remove thousands separator and DP - relies of n.nnn kHz format so we can do uint conversion
      reply = reply.mid (reply.indexOf ('>') + 1).replace (",", "").replace (".", "");
      update_rx_frequency (reply.toUInt ());
    }
  else
    {
#if WSJT_TRACE_CAT
      qDebug () << "DXLabSuiteCommanderTransceiver::poll: get frequency unexpected response";
#endif

      throw error {"DX Lab Suite Commander didn't respond correctly polling frequency"};
    }

  send_command ("<command:13>CmdSendTXFreq<parameters:0>", quiet);
  reply = read_reply (quiet);
  if (0 == reply.indexOf ("<CmdTXFreq:"))
    {
      // remove thousands separator and DP - relies of n.nnn kHz format so we ca do uint conversion
      auto text = reply.mid (reply.indexOf ('>') + 1).replace (",", "").replace (".", "");
      if ("000" != text)
	{
	  update_other_frequency (text.toUInt ());
	}
    }
  else
    {
#if WSJT_TRACE_CAT
      qDebug () << "DXLabSuiteCommanderTransceiver::poll: get tx frequency unexpected response";
#endif

      throw error {"DX Lab Suite Commander didn't respond correctly polling TX frequency"};
    }

  send_command ("<command:12>CmdSendSplit<parameters:0>", quiet);
  reply = read_reply (quiet);
  if (0 == reply.indexOf ("<CmdSplit:"))
    {
      auto split = reply.mid (reply.indexOf ('>') + 1);
      if ("ON" == split)
	{
	  update_split (true);
	}
      else if ("OFF" == split)
	{
	  update_split (false);
	}
      else
	{
#if WSJT_TRACE_CAT
	  qDebug () << "DXLabSuiteCommanderTransceiver::poll: unexpected split state" << split;
#endif

	  throw error {"DX Lab Suite Commander sent an unrecognised split state: " + split};
	}
    }
  else
    {
#if WSJT_TRACE_CAT
      qDebug () << "DXLabSuiteCommanderTransceiver::poll: get split mode unexpected response";
#endif

      throw error {"DX Lab Suite Commander didn't respond correctly polling split status"};
    }

  send_command ("<command:11>CmdSendMode<parameters:0>", quiet);
  reply = read_reply (quiet);
  if (0 == reply.indexOf ("<CmdMode:"))
    {
      auto mode = reply.mid (reply.indexOf ('>') + 1);
      MODE m {UNK};
      if ("AM" == mode)
	{
	  m = AM;
	}
      else if ("CW" == mode)
	{
	  m = CW;
	}
      else if ("CW-R" == mode)
	{
	  m = CW_R;
	}
      else if ("FM" == mode || "WBFM" == mode)
	{
	  m = FM;
	}
      else if ("LSB" == mode)
	{
	  m = LSB;
	}
      else if ("USB" == mode)
	{
	  m = USB;
	}
      else if ("RTTY" == mode)
	{
	  m = FSK;
	}
      else if ("RTTY-R" == mode)
	{
	  m = FSK_R;
	}
      else if ("PKT" == mode || "DATA-L" == mode || "Data-L" == mode)
	{
	  m = DIG_L;
	}
      else if ("PKT-R" == mode || "DATA-U" == mode || "Data-U" == mode)
	{
	  m = DIG_U;
	}
      else
	{
#if WSJT_TRACE_CAT
	  qDebug () << "DXLabSuiteCommanderTransceiver::poll: unexpected mode name" << mode;
#endif

	  throw error {"DX Lab Suite Commander sent an unrecognised mode: " + mode};
	}
      update_mode (m);
    }
  else
    {
#if WSJT_TRACE_CAT
      qDebug () << "DXLabSuiteCommanderTransceiver::poll: unexpected response";
#endif

      throw error {"DX Lab Suite Commander didn't respond correctly polling mode"};
    }
}

void DXLabSuiteCommanderTransceiver::send_command (QByteArray const& cmd, bool no_debug)
{
  Q_ASSERT (commander_);

  if (!no_debug)
    {
#if WSJT_TRACE_CAT
      qDebug () << "DXLabSuiteCommanderTransceiver:send_command(" << cmd << ')';
#endif
    }

  if (QTcpSocket::ConnectedState != commander_->state ())
    {
#if WSJT_TRACE_CAT
      qDebug () << "DXLabSuiteCommanderTransceiver::send_command failed:" << commander_->errorString ();
#endif

      throw error {"DX Lab Suite Commander send command failed\n" + commander_->errorString ().toLocal8Bit ()};
    }

  commander_->write (cmd);
  if (!commander_->waitForBytesWritten (socket_wait_time))
    {
#if WSJT_TRACE_CAT
      qDebug () << "DXLabSuiteCommanderTransceiver::send_command failed:" << commander_->errorString ();
#endif

      throw error {"DX Lab Suite Commander send command failed\n" + commander_->errorString ().toLocal8Bit ()};
    }
}

QByteArray DXLabSuiteCommanderTransceiver::read_reply (bool no_debug)
{
  Q_ASSERT (commander_);

  if (QTcpSocket::ConnectedState != commander_->state ())
    {
#if WSJT_TRACE_CAT
      qDebug () << "DXLabSuiteCommanderTransceiver::read_reply failed:" << commander_->errorString ();
#endif

      throw error {"DX Lab Suite Commander read reply failed\n" + commander_->errorString ().toLocal8Bit ()};
    }

  if (!commander_->waitForReadyRead (socket_wait_time))
    {
#if WSJT_TRACE_CAT
      qDebug () << "DXLabSuiteCommanderTransceiver::read_reply failed:" << commander_->errorString ();
#endif

      throw error {"DX Lab Suite Commander read reply failed\n" + commander_->errorString ().toLocal8Bit ()};
    }

  auto result = commander_->readAll ();

  if (!no_debug)
    {
#if WSJT_TRACE_CAT
      qDebug () << "DXLabSuiteCommanderTransceiver:read_reply() ->" << result;
#endif
    }

  return result;
}
