#include "NetworkMessage.hpp"

#include <exception>

#include <QString>
#include <QByteArray>

#include "pimpl_impl.hpp"

namespace NetworkMessage
{
  Builder::Builder (QIODevice * device, Type type, QString const& id)
    : QDataStream {device}
  {
    common_initialization (type, id);
  }

  Builder::Builder (QByteArray * a, Type type, QString const& id)
    : QDataStream {a, QIODevice::WriteOnly}
  {
    common_initialization (type, id);
  }

  void Builder::common_initialization (Type type, QString const& id)
  {
    *this << magic;
    *this << schema_number;
    setVersion (QDataStream::Qt_5_2); // Qt schema version
    *this << static_cast<quint32> (type) << id.toUtf8 ();
  }

  class Reader::impl
  {
  public:
    void common_initialization (Reader * parent)
    {
      quint32 magic;
      *parent >> magic;
      if (magic != Builder::magic)
        {
          throw std::runtime_error {"Invalid message format"};
        }
      *parent >> schema_;
      if (schema_ > Builder::schema_number)
        {
          throw std::runtime_error {"Unrecognized message schema"};
        }
      if (schema_ <= 1)
        {
          parent->setVersion (QDataStream::Qt_5_0);
        }
      else if (schema_ <= 2)
        {
          parent->setVersion (QDataStream::Qt_5_2);
        }
      quint32 type;
      *parent >> type >> id_;
      if (type >= maximum_message_type_)
        {
          throw std::runtime_error {"Unrecognized message type"};
        }
      type_ = static_cast<Type> (type);
    }

    quint32 schema_;
    Type type_;
    QByteArray id_;
  };

  Reader::Reader (QIODevice * device)
    : QDataStream {device}
  {
    m_->common_initialization (this);
  }

  Reader::Reader (QByteArray const& a)
    : QDataStream {a}
  {
    m_->common_initialization (this);
  }

  Reader::~Reader ()
  {
  }

  quint32 Reader::schema () const
  {
    return m_->schema_;
  }

  Type Reader::type () const
  {
    return static_cast<Type> (m_->type_);
  }

  QString Reader::id () const
  {
    return QString::fromUtf8 (m_->id_);
  }
}
