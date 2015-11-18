#ifndef MODES_HPP__
#define MODES_HPP__

#include <QAbstractListModel>

#include "qt_helpers.hpp"

class Modes final
  : public QAbstractListModel
{
  Q_OBJECT;
  Q_ENUMS (Mode);

public:
  enum Mode
  {
    NULL_MODE,
    JT65,
    JT9,
    JT4,
    WSPR,
    Echo,
    ISCAT,
    JTMSK,
  };

  explicit Modes (QObject * parent = nullptr);

  static char const * name (Mode);
  static Mode value (QString const&);

  // Implement the QAbstractListModel interface
  int rowCount (QModelIndex const& parent = QModelIndex {}) const override
  {
    return parent.isValid () ? 0 : 8; // Number of modes in Mode enumeration class
  }
  QVariant data (QModelIndex const&, int role = Qt::DisplayRole) const override;
  QVariant headerData (int section, Qt::Orientation, int = Qt::DisplayRole) const override;
};

Q_DECLARE_METATYPE (Modes::Mode);

#if !defined (QT_NO_DEBUG_STREAM)
ENUM_QDEBUG_OPS_DECL (Modes, Mode);
#endif

ENUM_QDATASTREAM_OPS_DECL (Modes, Mode);
ENUM_CONVERSION_OPS_DECL (Modes, Mode);

#endif
