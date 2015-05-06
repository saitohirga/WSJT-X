#include "MessageServer.hpp"

#include <stdexcept>

#include <QUdpSocket>
#include <QTimer>
#include <QHash>

#include "NetworkMessage.hpp"
#include "qt_helpers.hpp"

#include "pimpl_impl.hpp"

#include "moc_MessageServer.cpp"

class MessageServer::impl
  : public QUdpSocket
{
  Q_OBJECT;

public:
  impl (MessageServer * self)
    : self_ {self}
    , port_ {0u}
    , clock_ {new QTimer {this}}
  {
    connect (this, &QIODevice::readyRead, this, &MessageServer::impl::pending_datagrams);
    connect (this, static_cast<void (impl::*) (SocketError)> (&impl::error)
             , [this] (SocketError /* e */)
             {
               Q_EMIT self_->error (errorString ());
             });
    connect (clock_, &QTimer::timeout, this, &impl::tick);
    clock_->start (NetworkMessage::pulse * 1000);
  }

  void leave_multicast_group ();
  void join_multicast_group ();
  void parse_message (QHostAddress const& sender, port_type sender_port, QByteArray const& msg);
  void tick ();
  void pending_datagrams ();
  bool check_status (QDataStream const&) const;

  MessageServer * self_;
  port_type port_;
  QHostAddress multicast_group_address_;
  static BindMode const bind_mode_;
  struct Client
  {
    QHostAddress sender_address_;
    port_type sender_port_;
    QDateTime last_activity_;
  };
  QHash<QString, Client> clients_; // maps id to Client
  QTimer * clock_;
};

#include "MessageServer.moc"

MessageServer::impl::BindMode const MessageServer::impl::bind_mode_ = ShareAddress | ReuseAddressHint;

void MessageServer::impl::leave_multicast_group ()
{
  if (!multicast_group_address_.isNull () && BoundState == state ())
    {
      leaveMulticastGroup (multicast_group_address_);
    }
}

void MessageServer::impl::join_multicast_group ()
{
  if (BoundState == state ()
      && !multicast_group_address_.isNull ())
    {
      if (IPv4Protocol == multicast_group_address_.protocol ()
          && IPv4Protocol != localAddress ().protocol ())
        {
          close ();
          bind (QHostAddress::AnyIPv4, port_, bind_mode_);
        }
      if (!joinMulticastGroup (multicast_group_address_))
        {
          multicast_group_address_.clear ();
        }
    }
}

void MessageServer::impl::pending_datagrams ()
{
  while (hasPendingDatagrams ())
    {
      QByteArray datagram;
      datagram.resize (pendingDatagramSize ());
      QHostAddress sender_address;
      port_type sender_port;
      if (0 <= readDatagram (datagram.data (), datagram.size (), &sender_address, &sender_port))
        {
          parse_message (sender_address, sender_port, datagram);
        }
    }
}

void MessageServer::impl::parse_message (QHostAddress const& sender, port_type sender_port, QByteArray const& msg)
{
  try
    {
      //
      // message format is described in NetworkMessage.hpp
      //
      NetworkMessage::Reader in {msg};

      auto id = in.id ();
      bool new_client {false};
      if (!clients_.contains (id))
        {
          new_client = true;
        }
      clients_[id] = {sender, sender_port, QDateTime::currentDateTime ()};
      if (new_client)
        {
          Q_EMIT self_->client_opened (id);
        }
  
      //
      // message format is described in NetworkMessage.hpp
      //
      switch (in.type ())
        {
        case NetworkMessage::Heartbeat:
          //nothing to do here as time out handling deals with lifetime
          break;

        case NetworkMessage::Clear:
          Q_EMIT self_->clear_decodes (id);
          break;

        case NetworkMessage::Status:
          {
            // unpack message
            Frequency f;
            QByteArray mode;
            QByteArray dx_call;
            QByteArray report;
            QByteArray tx_mode;
            bool transmitting;
            in >> f >> mode >> dx_call >> report >> tx_mode >> transmitting;
            if (check_status (in))
              {
                Q_EMIT self_->status_update (id, f, QString::fromUtf8 (mode), QString::fromUtf8 (dx_call)
                                             , QString::fromUtf8 (report), QString::fromUtf8 (tx_mode)
                                             , transmitting);
              }
          }
          break;

        case NetworkMessage::Decode:
          {
            // unpack message
            bool is_new;
            QTime time;
            qint32 snr;
            float delta_time;
            quint32 delta_frequency;
            QByteArray mode;
            QByteArray message;
            in >> is_new >> time >> snr >> delta_time >> delta_frequency >> mode >> message;
            if (check_status (in))
              {
                Q_EMIT self_->decode (is_new, id, time, snr, delta_time, delta_frequency
                                      , QString::fromUtf8 (mode), QString::fromUtf8 (message));
              }
          }
          break;

        case NetworkMessage::QSOLogged:
          {
            QDateTime time;
            QByteArray dx_call;
            QByteArray dx_grid;
            Frequency dial_frequency;
            QByteArray mode;
            QByteArray report_sent;
            QByteArray report_received;
            QByteArray tx_power;
            QByteArray comments;
            QByteArray name;
            in >> time >> dx_call >> dx_grid >> dial_frequency >> mode >> report_sent >> report_received
               >> tx_power >> comments >> name;
            if (check_status (in))
              {
                Q_EMIT self_->qso_logged (id, time, QString::fromUtf8 (dx_call), QString::fromUtf8 (dx_grid)
                                          , dial_frequency, QString::fromUtf8 (mode), QString::fromUtf8 (report_sent)
                                          , QString::fromUtf8 (report_received), QString::fromUtf8 (tx_power)
                                          , QString::fromUtf8 (comments), QString::fromUtf8 (name));
              }
          }
          break;

        case NetworkMessage::Close:
          if (check_status (in))
            {
              Q_EMIT self_->client_closed (id);
              clients_.remove (id);
            }
          break;

        default:
          // Ignore
          break;
        }
    }
  catch (std::exception const& e)
    {
      Q_EMIT self_->error (QString {"MessageServer exception: %1"}.arg (e.what ()));
    }
  catch (...)
    {
      Q_EMIT self_->error ("Unexpected exception in MessageServer");
    }
}

void MessageServer::impl::tick ()
{
  auto now = QDateTime::currentDateTime ();
  for (auto iter = std::begin (clients_); iter != std::end (clients_); ++iter)
    {
      if (now > (*iter).last_activity_.addSecs (NetworkMessage::pulse))
        {
          Q_EMIT self_->clear_decodes (iter.key ());
          Q_EMIT self_->client_closed (iter.key ());
          clients_.erase (iter); // safe while iterating as doesn't rehash
        }
    }
}

bool MessageServer::impl::check_status (QDataStream const& stream) const
{
  auto stat = stream.status ();
  switch (stat)
    {
    case QDataStream::ReadPastEnd:
      Q_EMIT self_->error ("Message serialization error: read failed");
      break;

    case QDataStream::ReadCorruptData:
      Q_EMIT self_->error ("Message serialization error: read corrupt data");
      break;

    case QDataStream::WriteFailed:
      Q_EMIT self_->error ("Message serialization error: write error");
      break;

    default:
      break;
    }
  return QDataStream::Ok == stat;
}

MessageServer::MessageServer (QObject * parent)
  : QObject {parent}
  , m_ {this}
{
}

void MessageServer::start (port_type port, QHostAddress const& multicast_group_address)
{
  if (port != m_->port_
      || multicast_group_address != m_->multicast_group_address_)
    {
      m_->leave_multicast_group ();
      if (impl::BoundState == m_->state ())
        {
          m_->close ();
        }
      m_->multicast_group_address_ = multicast_group_address;
      auto address = m_->multicast_group_address_.isNull ()
        || impl::IPv4Protocol != m_->multicast_group_address_.protocol () ? QHostAddress::Any : QHostAddress::AnyIPv4;
      if (port && m_->bind (address, port, m_->bind_mode_))
        {
          m_->port_ = port;
          m_->join_multicast_group ();
        }
      else
        {
          m_->port_ = 0;
        }
    }
}

void MessageServer::reply (QString const& id, QTime time, qint32 snr, float delta_time, quint32 delta_frequency, QString const& mode, QString const& message_text)
{
  auto iter = m_->clients_.find (id);
  if (iter != std::end (m_->clients_))
    {
      QByteArray message;
      NetworkMessage::Builder out {&message, NetworkMessage::Reply, id};
      out << time << snr << delta_time << delta_frequency << mode.toUtf8 () << message_text.toUtf8 ();
      if (m_->check_status (out))
        {
          m_->writeDatagram (message, iter.value ().sender_address_, (*iter).sender_port_);
        }
    }
}

void MessageServer::replay (QString const& id)
{
  auto iter = m_->clients_.find (id);
  if (iter != std::end (m_->clients_))
    {
      QByteArray message;
      NetworkMessage::Builder out {&message, NetworkMessage::Replay, id};
      if (m_->check_status (out))
        {
          m_->writeDatagram (message, iter.value ().sender_address_, (*iter).sender_port_);
        }
    }
}

void MessageServer::halt_tx (QString const& id)
{
  auto iter = m_->clients_.find (id);
  if (iter != std::end (m_->clients_))
    {
      QByteArray message;
      NetworkMessage::Builder out {&message, NetworkMessage::HaltTx, id};
      if (m_->check_status (out))
        {
          m_->writeDatagram (message, iter.value ().sender_address_, (*iter).sender_port_);
        }
    }
}

void MessageServer::free_text (QString const& id, QString const& text)
{
  auto iter = m_->clients_.find (id);
  if (iter != std::end (m_->clients_))
    {
      QByteArray message;
      NetworkMessage::Builder out {&message, NetworkMessage::FreeText, id};
      out << text.toUtf8 ();
      if (m_->check_status (out))
        {
          m_->writeDatagram (message, iter.value ().sender_address_, (*iter).sender_port_);
        }
    }
}
