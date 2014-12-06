#include "DXLabSuiteCommanderTransceiver.hpp"

#include <QTcpSocket>
#include <QRegularExpression>
#include <QLocale>

#include "NetworkServerLookup.hpp"

#include "moc_DXLabSuiteCommanderTransceiver.cpp"

namespace
{
  char const * const commander_transceiver_name {"DX Lab Suite Commander"};

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
  if (!commander_->waitForConnected ())
    {
#if WSJT_TRACE_CAT
      qDebug () << "DXLabSuiteCommanderTransceiver::start failed to connect" << commander_->errorString ();
#endif

      throw error {tr ("Failed to connect to DX Lab Suite Commander\n") + commander_->errorString ()};
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
      simple_command (on  ? "<command:5>CmdTX<parameters:0>" : "<command:5>CmdRX<parameters:0>");
    }
  else
    {
      wrapped_->ptt (on);
    }

  update_PTT (on);
}

void DXLabSuiteCommanderTransceiver::do_frequency (Frequency f, MODE m)
{
#if WSJT_TRACE_CAT
  qDebug () << "DXLabSuiteCommanderTransceiver::do_frequency:" << f << state ();
#endif

  auto f_string = frequency_to_string (f);
  if (UNK != m)
    {
      auto m_string = map_mode (m);
      auto params =  ("<xcvrfreq:%1>" + f_string + "<xcvrmode:%2>" + m_string + "<preservesplitanddual:1>Y").arg (f_string.size ()).arg (m_string.size ());
      simple_command (("<command:14>CmdSetFreqMode<parameters:%1>" + params).arg (params.size ()));
      update_mode (m);
    }
  else
    {
      auto params =  ("<xcvrfreq:%1>" + f_string).arg (f_string.size ());
      simple_command (("<command:10>CmdSetFreq<parameters:%1>" + params).arg (params.size ()));
    }
  update_rx_frequency (f);
}

void DXLabSuiteCommanderTransceiver::do_tx_frequency (Frequency tx, bool /* rationalise_mode */)
{
#if WSJT_TRACE_CAT
  qDebug () << "DXLabSuiteCommanderTransceiver::do_tx_frequency:" << tx << state ();
#endif

  if (tx)
    {
      auto f_string = frequency_to_string (tx);
      auto params = ("<xcvrfreq:%1>" + f_string + "<SuppressDual:1>Y").arg (f_string.size ());
      simple_command (("<command:11>CmdQSXSplit<parameters:%1>" + params).arg (params.size ()));
    }
  else
    {
      simple_command ("<command:8>CmdSplit<parameters:8><1:3>off");
    }
  update_split (tx);
  update_other_frequency (tx);
}

void DXLabSuiteCommanderTransceiver::do_mode (MODE m, bool /* rationalise */)
{
#if WSJT_TRACE_CAT
  qDebug () << "DXLabSuiteCommanderTransceiver::do_mode:" << m << state ();
#endif

  auto m_string = map_mode (m);
  auto params =  ("<1:%1>" + m_string).arg (m_string.size ());

  simple_command (("<command:10>CmdSetMode<parameters:%1>" + params).arg (params.size ()));

  update_mode (m);
}

void DXLabSuiteCommanderTransceiver::poll ()
{
#if WSJT_TRACE_CAT && WSJT_TRACE_CAT_POLLS
  bool quiet {false};
#else
  bool quiet {true};
#endif

  auto reply = command_with_reply ("<command:10>CmdGetFreq<parameters:0>", quiet);
  if (0 == reply.indexOf ("<CmdFreq:"))
    {
      auto f = string_to_frequency (reply.mid (reply.indexOf ('>') + 1));
      if (f)
        {
          if (!state ().ptt ()) // Commander is not reliable on frequency
                                // polls while transmitting
            {
              update_rx_frequency (f);
            }
        }
    }
  else
    {
#if WSJT_TRACE_CAT
      qDebug () << "DXLabSuiteCommanderTransceiver::poll: get frequency unexpected response";
#endif

      throw error {tr ("DX Lab Suite Commander didn't respond correctly polling frequency")};
    }

  if (state ().split ())
    {
      reply = command_with_reply ("<command:12>CmdGetTXFreq<parameters:0>", quiet);
      if (0 == reply.indexOf ("<CmdTXFreq:"))
        {
          auto f = string_to_frequency (reply.mid (reply.indexOf ('>') + 1));
          if (f)
            {
              if (!state ().ptt ()) // Commander is not reliable on frequency
                                // polls while transmitting
                {
                  update_other_frequency (f);
                }
            }
        }
      else
        {
#if WSJT_TRACE_CAT
          qDebug () << "DXLabSuiteCommanderTransceiver::poll: get tx frequency unexpected response";
#endif

          throw error {tr ("DX Lab Suite Commander didn't respond correctly polling TX frequency")};
        }
    }

  reply = command_with_reply ("<command:12>CmdSendSplit<parameters:0>", quiet);
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

          throw error {tr ("DX Lab Suite Commander sent an unrecognised split state: ") + split};
        }
    }
  else
    {
#if WSJT_TRACE_CAT
      qDebug () << "DXLabSuiteCommanderTransceiver::poll: get split mode unexpected response";
#endif

      throw error {tr ("DX Lab Suite Commander didn't respond correctly polling split status")};
    }

  reply = command_with_reply ("<command:11>CmdSendMode<parameters:0>", quiet);
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

          throw error {tr ("DX Lab Suite Commander sent an unrecognised mode: ") + mode};
        }
      update_mode (m);
    }
  else
    {
#if WSJT_TRACE_CAT
      qDebug () << "DXLabSuiteCommanderTransceiver::poll: unexpected response";
#endif

      throw error {tr ("DX Lab Suite Commander didn't respond correctly polling mode")};
    }
}

void DXLabSuiteCommanderTransceiver::simple_command (QString const& cmd, bool no_debug)
{
  Q_ASSERT (commander_);

  if (!no_debug)
    {
#if WSJT_TRACE_CAT
      qDebug () << "DXLabSuiteCommanderTransceiver:simple_command(" << cmd << ')';
#endif
    }

  if (!write_to_port (cmd))
    {
#if WSJT_TRACE_CAT
      qDebug () << "DXLabSuiteCommanderTransceiver::simple_command failed:" << commander_->errorString ();
#endif

      throw error {tr ("DX Lab Suite Commander send command failed\n") + commander_->errorString ()};
    }
}

QString DXLabSuiteCommanderTransceiver::command_with_reply (QString const& cmd, bool no_debug)
{
  Q_ASSERT (commander_);

  if (!write_to_port (cmd))
    {
#if WSJT_TRACE_CAT
      qDebug () << "DXLabSuiteCommanderTransceiver::command_with_reply failed to send command:" << commander_->errorString ();
#endif

      throw error {
        tr ("DX Lab Suite Commander failed to send command \"%1\": %2\n")
          .arg (cmd)
          .arg (commander_->errorString ())
          };
    }

  // waitForReadReady appears to be unreliable on Windows timing out
  // when data is waiting so retry a few times
  unsigned retries {5};
  bool replied {false};
  while (!replied && --retries)
    {
      replied = commander_->waitForReadyRead ();
      if (!replied && commander_->error () != commander_->SocketTimeoutError)
        {
#if WSJT_TRACE_CAT
          qDebug () << "DXLabSuiteCommanderTransceiver::command_with_reply \"" << cmd << "\" failed to read reply:" << commander_->errorString ();
#endif

          throw error {
            tr ("DX Lab Suite Commander send command \"%1\" read reply failed: %2\n")
              .arg (cmd)
              .arg (commander_->errorString ())
              };
        }
    }

  if (!replied)
    {
#if WSJT_TRACE_CAT
      qDebug () << "DXLabSuiteCommanderTransceiver::command_with_reply \"" << cmd << "\" retries exhausted";
#endif

      throw error {
        tr ("DX Lab Suite Commander retries exhausted sending command \"%1\"")
          .arg (cmd)
          };
    }

  auto result = commander_->readAll ();
  // qDebug () << "result: " << result;
  // for (int i = 0; i < result.size (); ++i)
  //   {
  //     qDebug () << i << ":" << hex << int (result[i]);
  //   }

  if (!no_debug)
    {
#if WSJT_TRACE_CAT
      qDebug () << "DXLabSuiteCommanderTransceiver:command_with_reply(" << cmd << ") ->" << result;
#endif
    }

  return result;                // converting raw UTF-8 bytes to QString
}

bool DXLabSuiteCommanderTransceiver::write_to_port (QString const& s)
{
  auto data = s.toLocal8Bit ();
  auto to_send = data.constData ();
  auto length = data.size ();

  qint64 total_bytes_sent {0};
  while (total_bytes_sent < length)
    {
      auto bytes_sent = commander_->write (to_send + total_bytes_sent, length - total_bytes_sent);
      if (bytes_sent < 0 || !commander_->waitForBytesWritten ())
        {
          return false;
        }

      total_bytes_sent += bytes_sent;
    }
  return true;
}

QString DXLabSuiteCommanderTransceiver::frequency_to_string (Frequency f) const
{
  // number is localized and in kHz, avoid floating point translation
  // errors by adding a small number (0.1Hz)
  return QString {"%L1"}.arg (f / 1e3 + 1e-4, 10, 'f', 3);
}

auto DXLabSuiteCommanderTransceiver::string_to_frequency (QString s) const -> Frequency
{
  // temporary hack because Commander is returning invalid UTF-8 bytes
  s.replace (QChar {QChar::ReplacementCharacter}, locale_.groupSeparator ());

  // remove DP - relies on n.nnn kHz format so we can do ulonglong
  // conversion to Hz
  bool ok;

  //  auto f = locale_.toDouble (s, &ok); // use when CmdSendFreq and
                                      // CmdSendTxFreq reinstated

  auto f = QLocale::c ().toDouble (s, &ok); // temporary fix

  if (!ok)
    {
      throw error {tr ("DX Lab Suite Commander sent an unrecognized frequency")};
    }
  return (f + 1e-4) * 1e3;
}
