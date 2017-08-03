//
// UDPDaemon - an example console application that utilizes the WSJT-X
//             messaging facility
//
// This application is  only provided as a  simple console application
// example to  demonstrate the  WSJT-X messaging facility.   It allows
// the user to  set the server details either as  a unicast UDP server
// or,  if a  multicast  group  address is  provided,  as a  multicast
// server.   The benefit  of  the multicast  server  is that  multiple
// servers can be  active at once each receiving  all WSJT-X broadcast
// messages and each able to respond to individual WSJT_X clients.  To
// utilize the  multicast group features  each WSJT-X client  must set
// the  same multicast  group address  as the  UDP server  address for
// example 239.255.0.0 for a site local multicast group.
//
//

#include <iostream>
#include <exception>

#include <QCoreApplication>
#include <QCommandLineParser>
#include <QDateTime>
#include <QTime>
#include <QHash>
#include <QDebug>

#include "MessageServer.hpp"
#include "Radio.hpp"

#include "qt_helpers.hpp"

using port_type = MessageServer::port_type;
using Frequency = MessageServer::Frequency;

class Client
  : public QObject
{
  Q_OBJECT

public:
  explicit Client (QString const& id, QObject * parent = nullptr)
    : QObject {parent}
    , id_ {id}
    , dial_frequency_ {0u}
  {
  }

  Q_SLOT void update_status (QString const& id, Frequency f, QString const& mode, QString const& /*dx_call*/
                             , QString const& /*report*/, QString const& /*tx_mode*/, bool /*tx_enabled*/
                             , bool /*transmitting*/, bool /*decoding*/, qint32 /*rx_df*/, qint32 /*tx_df*/
                             , QString const& /*de_call*/, QString const& /*de_grid*/, QString const& /*dx_grid*/
                             , bool /* watchdog_timeout */, QString const& sub_mode, bool /*fast_mode*/)
  {
    if (id == id_)
      {
        if (f != dial_frequency_)
          {
            std::cout << tr ("%1: Dial frequency changed to %2").arg (id_).arg (f).toStdString () << std::endl;
            dial_frequency_ = f;
          }
        if (mode + sub_mode != mode_)
          {
            std::cout << tr ("%1: Mode changed to %2").arg (id_).arg (mode + sub_mode).toStdString () << std::endl;
            mode_ = mode + sub_mode;
          }
      }
  }

  Q_SLOT void decode_added (bool is_new, QString const& client_id, QTime time, qint32 snr
      , float delta_time, quint32 delta_frequency, QString const& mode
                            , QString const& message, bool low_confidence)
  {
    if (client_id == id_)
      {
        qDebug () << "new:" << is_new << "t:" << time << "snr:" << snr
                  << "Dt:" << delta_time << "Df:" << delta_frequency
                  << "mode:" << mode << "Confidence:" << (low_confidence ? "low" : "high");
        std::cout << tr ("%1: Decoded %2").arg (id_).arg (message).toStdString () << std::endl;
      }
  }

  Q_SLOT void beacon_spot_added (bool is_new, QString const& client_id, QTime time, qint32 snr
      , float delta_time, Frequency delta_frequency, qint32 drift, QString const& callsign
      , QString const& grid, qint32 power)
  {
    if (client_id == id_)
      {
        qDebug () << "new:" << is_new << "t:" << time << "snr:" << snr
                  << "Dt:" << delta_time << "Df:" << delta_frequency
                  << "drift:" << drift;
        std::cout << tr ("%1: WSPR decode %2 grid %3 power: %4").arg (id_).arg (callsign).arg (grid).arg (power).toStdString () << std::endl;
      }
  }

private:
  QString id_;
  Frequency dial_frequency_;
  QString mode_;
};

class Server
  : public QObject
{
  Q_OBJECT

public:
  Server (port_type port, QHostAddress const& multicast_group)
    : server_ {new MessageServer {this}}
  {
    // connect up server
    connect (server_, &MessageServer::error, [this] (QString const& message) {
        std::cerr << tr ("Network Error: %1").arg ( message).toStdString () << std::endl;
      });
    connect (server_, &MessageServer::client_opened, this, &Server::add_client);
    connect (server_, &MessageServer::client_closed, this, &Server::remove_client);

    server_->start (port, multicast_group);
  }

private:
  void add_client (QString const& id, QString const& version, QString const& revision)
  {
    auto client = new Client {id};
    connect (server_, &MessageServer::status_update, client, &Client::update_status);
    connect (server_, &MessageServer::decode, client, &Client::decode_added);
    connect (server_, &MessageServer::WSPR_decode, client, &Client::beacon_spot_added);
    clients_[id] = client;
    server_->replay (id);
    std::cout << "Discovered WSJT-X instance: " << id.toStdString ();
    if (version.size ())
      {
        std::cout << " v" << version.toStdString ();
      }
    if (revision.size ())
      {
        std::cout << " (" << revision.toStdString () << ")";
      }
    std::cout << std::endl;
  }

  void remove_client (QString const& id)
  {
    auto iter = clients_.find (id);
    if (iter != std::end (clients_))
      {
        clients_.erase (iter);
        (*iter)->deleteLater ();
      }
    std::cout << "Removed WSJT-X instance: " << id.toStdString () << std::endl;
  }

  MessageServer * server_;

  // maps client id to clients
  QHash<QString, Client *> clients_;
};

#include "UDPDaemon.moc"

int main (int argc, char * argv[])
{
  QCoreApplication app {argc, argv};
  try
    {
      setlocale (LC_NUMERIC, "C"); // ensure number forms are in
                                   // consistent format, do this after
                                   // instantiating QApplication so
                                   // that GUI has correct l18n

      app.setApplicationName ("WSJT-X UDP Message Server Daemon");
      app.setApplicationVersion ("1.0");

      QCommandLineParser parser;
      parser.setApplicationDescription ("\nWSJT-X UDP Message Server Daemon.");
      auto help_option = parser.addHelpOption ();
      auto version_option = parser.addVersionOption ();

      QCommandLineOption port_option (QStringList {"p", "port"},
                                      app.translate ("UDPDaemon",
                                                     "Where <PORT> is the UDP service port number to listen on.\n"
                                                     "The default service port is 2237."),
                                      app.translate ("UDPDaemon", "PORT"),
                                      "2237");
      parser.addOption (port_option);

      QCommandLineOption multicast_addr_option (QStringList {"g", "multicast-group"},
                                                app.translate ("UDPDaemon",
                                                               "Where <GROUP> is the multicast group to join.\n"
                                                               "The default is a unicast server listening on all interfaces."),
                                                app.translate ("UDPDaemon", "GROUP"));
      parser.addOption (multicast_addr_option);

      parser.process (app);

      Server server {static_cast<port_type> (parser.value (port_option).toUInt ()), QHostAddress {parser.value (multicast_addr_option)}};

      return app.exec ();
    }
  catch (std::exception const & e)
    {
      std::cerr << "Error: " << e.what () << '\n';
    }
  catch (...)
    {
      std::cerr << "Unexpected error\n";
    }
  return -1;
}
