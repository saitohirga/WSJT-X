#ifndef QT_HELPERS_HPP_
#define QT_HELPERS_HPP_

#include <stdexcept>

#include <QString>
#include <QMetaObject>
#include <QHostAddress>
#include <QDataStream>
#include <QMetaType>
#include <QMetaEnum>

#define ENUM_QDATASTREAM_OPS_DECL(CLASS, ENUM)				\
  QDataStream& operator << (QDataStream&, CLASS::ENUM const&);			\
  QDataStream& operator >> (QDataStream&, CLASS::ENUM&);

#define ENUM_QDATASTREAM_OPS_IMPL(CLASS, ENUM)				\
  QDataStream& operator << (QDataStream& os, CLASS::ENUM const& v)		\
  {									\
    auto const& mo = CLASS::staticMetaObject;				\
    return os << mo.enumerator (mo.indexOfEnumerator (#ENUM)).valueToKey (static_cast<int> (v)); \
  }									\
									\
  QDataStream& operator >> (QDataStream& is, CLASS::ENUM& v)		\
  {									\
    char * buffer;							\
    is >> buffer;							\
    bool ok {false};							\
    auto const& mo = CLASS::staticMetaObject;				\
    auto const& me = mo.enumerator (mo.indexOfEnumerator (#ENUM)); \
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

#define ENUM_CONVERSION_OPS_DECL(CLASS, ENUM)	\
  QString enum_to_qstring (CLASS::ENUM const&);

#define ENUM_CONVERSION_OPS_IMPL(CLASS, ENUM)				\
  QString enum_to_qstring (CLASS::ENUM const& m)				\
  {									\
    auto const& mo = CLASS::staticMetaObject;				\
    return QString {mo.enumerator (mo.indexOfEnumerator (#ENUM)).valueToKey (static_cast<int> (m))}; \
  }

inline
void throw_qstring (QString const& qs)
{
  throw std::runtime_error {qs.toLocal8Bit ().constData ()};
}

QString font_as_stylesheet (QFont const&);

// do what is necessary to change a dynamic property and trigger any
// conditional style sheet updates
void update_dynamic_property (QWidget *, char const * property, QVariant const& value);

template <class T>
class VPtr
{
public:
  static T * asPtr (QVariant v)
  {
    return reinterpret_cast<T *> (v.value<void *> ());
  }

  static QVariant asQVariant(T * ptr)
  {
    return qVariantFromValue (reinterpret_cast<void *> (ptr));
  }
};

// Register some useful Qt types with QMetaType
Q_DECLARE_METATYPE (QHostAddress);

#endif
