#ifndef NETWORK_MESSAGE_HPP__
#define NETWORK_MESSAGE_HPP__

/*
 * WSJT-X Message Formats
 * ======================
 *
 * All messages are written or  read using the QDataStream derivatives
 * defined below, note that we are using the default for floating
 * point precision which means all are double precision i.e. 64-bit
 * IEEE format.
 *
 *  Message is big endian format
 *
 *   Header format:
 *
 *      32-bit unsigned integer magic number 0xadbccbda
 *      32-bit unsigned integer schema number
 *
 *   Payload format:
 *
 *      As per  the QDataStream format,  see below for version  used and
 *      here:
 *
 *        http://doc.qt.io/qt-5/datastreamformat.html
 *
 *      for the serialization details for each type, at the time of
 *      writing the above document is for Qt_5_0 format which is buggy
 *      so we use Qt_5_2 format, differences are:
 *
 *      QDateTime:
 *           QDate      qint64    Julian day number
 *           QTime      quint32   Milli-seconds since midnight
 *           timespec   quint8    0=local, 1=UTC, 2=Offset from UTC
 *                                                 (seconds)
 *                                3=time zone
 *           offset     qint32    only present if timespec=2
 *           timezone   several-fields only present if timespec=3
 *
 *      we will avoid using QDateTime fields with time zones for simplicity.
 *
 * Type utf8  is a  utf-8 byte  string formatted  as a  QByteArray for
 * serialization purposes  (currently a quint32 size  followed by size
 * bytes, no terminator is present or counted).
 *
 * The QDataStream format document linked above is not complete for
 * the QByteArray serialization format, it is similar to the QString
 * serialization format in that it differentiates between empty
 * strings and null strings. Empty strings have a length of zero
 * whereas null strings have a length field of 0xffffffff.
 *
 * Schema Version 1:
 * -----------------
 *
 * Message       Direction Value                  Type
 * ------------- --------- ---------------------- -----------
 * Heartbeat     Out       0                      quint32
 *                         Id (unique key)        utf8
 *
 * Status        Out       1                      quint32
 *                         Id (unique key)        utf8
 *                         Dial Frequency (Hz)    quint64
 *                         Mode                   utf8
 *                         DX call                utf8
 *                         Report                 utf8
 *                         Tx Mode                utf8
 *                         Tx Enabled             bool
 *                         Transmitting           bool
 *
 * Decode        Out       2                      quint32
 *                         Id (unique key)        utf8
 *                         New                    bool
 *                         Time                   QTime
 *                         snr                    qint32
 *                         Delta time (S)         float (serialized as double)
 *                         Delta frequency (Hz)   quint32
 *                         Mode                   utf8
 *                         Message                utf8
 *
 * Clear         Out       3                      quint32
 *                         Id (unique key)        utf8
 *
 * Reply         In        4                      quint32
 *                         Id (target unique key) utf8
 *                         Time                   QTime
 *                         snr                    qint32
 *                         Delta time (S)         float (serialized as double)
 *                         Delta frequency (Hz)   quint32
 *                         Mode                   utf8
 *                         Message                utf8
 *
 * QSO Logged    Out       5                      quint32
 *                         Id (unique key)        utf8
 *                         Date & Time            QDateTime
 *                         DX call                utf8
 *                         DX grid                utf8
 *                         Dial frequency (Hz)    quint64
 *                         Mode                   utf8
 *                         Report send            utf8
 *                         Report received        utf8
 *                         Tx power               utf8
 *                         Comments               utf8
 *                         Name                   utf8
 *
 * Close         Out       6                      quint32
 *                         Id (unique key)        utf8
 *
 * Replay        In        7                      quint32
 *                         Id (unique key)        utf8
 *
 * Halt Tx       In        8
 *                         Id (unique key)        utf8
 *                         Auto Tx Only           bool
 *
 * Free Text     In        9
 *                         Id (unique key)        utf8
 *                         Text                   utf8
 */

#include <QDataStream>

#include "pimpl_h.hpp"

class QIODevice;
class QByteArray;
class QString;

namespace NetworkMessage
{
  // NEVER DELETE MESSAGE TYPES
  enum Type
    {
      Heartbeat,
      Status,
      Decode,
      Clear,
      Reply,
      QSOLogged,
      Close,
      Replay,
      HaltTx,
      FreeText,
      maximum_message_type_     // ONLY add new message types
                                // immediately before here
    };

  quint32 constexpr pulse {15}; // seconds

  //
  // NetworkMessage::Build - build a message containing serialized Qt types
  //
  class Builder
    : public QDataStream
  {
  public:
    static quint32 constexpr magic {0xadbccbda}; // never change this

    // increment this if a newer Qt schema is required and add decode
    // logic to InputMessageStream below
    static quint32 constexpr schema_number {2};

    explicit Builder (QIODevice *, Type, QString const& id);
    explicit Builder (QByteArray *, Type, QString const& id);
    Builder (Builder const&) = delete;
    Builder& operator = (Builder const&) = delete;

  private:
    void common_initialization (Type type, QString const& id);
  };

  //
  // NetworkMessage::Reader - read a message containing serialized Qt types
  //
  // Message  is as  per NetworkMessage::Builder  above, the  schema()
  // member  may be  used  to  determine the  schema  of the  original
  // message.
  //
  class Reader
    : public QDataStream
  {
  public:
    explicit Reader (QIODevice *);
    explicit Reader (QByteArray const&);
    Reader (Reader const&) = delete;
    Reader& operator = (Reader const&) = delete;
    ~Reader ();

    quint32 schema () const;
    Type type () const;
    QString id () const;

  private:
    class impl;
    pimpl<impl> m_;
  };
}

#endif
