#ifndef QT_HELPERS_HPP_
#define QT_HELPERS_HPP_

#include <stdexcept>

#include <QDataStream>
#include <QMetaObject>
#include <QMetaEnum>
#include <QString>
#include <QByteArray>
#include <QDebug>

#define ENUM_QDATASTREAM_OPS_DECL(CLASS, ENUM)				\
  QDataStream& operator << (QDataStream&, CLASS::ENUM);			\
  QDataStream& operator >> (QDataStream&, CLASS::ENUM&);

#define ENUM_QDATASTREAM_OPS_IMPL(CLASS, ENUM)				\
  QDataStream& operator << (QDataStream& os, CLASS::ENUM v)		\
  {									\
    auto const& mo = CLASS::staticMetaObject;				\
    return os << mo.enumerator (mo.indexOfEnumerator (#ENUM)).valueToKey (v); \
  }									\
									\
  QDataStream& operator >> (QDataStream& is, CLASS::ENUM& v)		\
  {									\
    char * buffer;							\
    is >> buffer;							\
    bool ok {false};							\
    auto const& mo = CLASS::staticMetaObject;				\
    auto const& me = mo.enumerator (mo.indexOfEnumerator (#ENUM));	\
    if (buffer)								\
      {									\
	v = static_cast<CLASS::ENUM> (me.keyToValue (buffer, &ok));	\
	delete [] buffer;						\
      }									\
    if (!ok)								\
      {									\
	v = static_cast<CLASS::ENUM> (me.value (0));			\
      }									\
    return is;								\
  }

#define ENUM_QDEBUG_OPS_DECL(CLASS, ENUM)				\
  QDebug operator << (QDebug, CLASS::ENUM);

#define ENUM_QDEBUG_OPS_IMPL(CLASS, ENUM)				\
  QDebug operator << (QDebug d, CLASS::ENUM m)				\
  {									\
    auto const& mo = CLASS::staticMetaObject;				\
    return d << mo.enumerator (mo.indexOfEnumerator (#ENUM)).valueToKey (m); \
  }

#define ENUM_CONVERSION_OPS_DECL(CLASS, ENUM)	\
  QString enum_to_qstring (CLASS::ENUM);

#define ENUM_CONVERSION_OPS_IMPL(CLASS, ENUM)				\
  QString enum_to_qstring (CLASS::ENUM m)				\
  {									\
    auto const& mo = CLASS::staticMetaObject;				\
    return QString {mo.enumerator (mo.indexOfEnumerator (#ENUM)).valueToKey (m)}; \
  }

inline
void throw_qstring (QString const& qs)
{
  throw std::runtime_error (qs.toLocal8Bit ().data ());
}

QString font_as_stylesheet (QFont const&);

#endif
