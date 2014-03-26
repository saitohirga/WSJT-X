#include "StationList.hpp"

#include <utility>
#include <algorithm>
#include <cmath>

#include <QMetaType>
#include <QAbstractTableModel>
#include <QObject>
#include <QString>
#include <QVector>
#include <QStringList>
#include <QMimeData>
#include <QDataStream>
#include <QByteArray>
#include <QDebug>

#include "pimpl_impl.hpp"

#include "Bands.hpp"

namespace
{
  struct init
  {
    init ()
    {
      qRegisterMetaType<StationList::Station> ("Station");
      qRegisterMetaTypeStreamOperators<StationList::Station> ("Station");
      qRegisterMetaType<StationList::Stations> ("Stations");
      qRegisterMetaTypeStreamOperators<StationList::Stations> ("Stations");
    }
  } static_initializer;
}

#if !defined (QT_NO_DEBUG_STREAM)
QDebug operator << (QDebug debug, StationList::Station const& station)
{
  debug.nospace () << "Station("
                   << station.band_name_ << ", "
                   << station.offset_ << ", "
                   << station.antenna_description_ << ')';
  return debug.space ();
}
#endif

QDataStream& operator << (QDataStream& os, StationList::Station const& station)
{
  return os << station.band_name_
            << station.offset_
            << station.antenna_description_;
}

QDataStream& operator >> (QDataStream& is, StationList::Station& station)
{
  return is >> station.band_name_
            >> station.offset_
            >> station.antenna_description_;
}


class StationList::impl final
  : public QAbstractTableModel
{
public:
  impl (Bands const * bands, Stations stations, QObject * parent)
    : QAbstractTableModel {parent}
    , bands_ {bands}
    , stations_ {stations}
  {
  }

  Stations const& stations () const {return stations_;}
  void assign (Stations);
  QModelIndex add (Station);
  FrequencyDelta offset (Frequency) const;

protected:
  // Implement the QAbstractTableModel interface.
  int rowCount (QModelIndex const& parent = QModelIndex {}) const override;
  int columnCount (QModelIndex const& parent = QModelIndex {}) const override;
  Qt::ItemFlags flags (QModelIndex const& = QModelIndex {}) const override;
  QVariant data (QModelIndex const&, int role) const override;
  QVariant headerData (int section, Qt::Orientation, int = Qt::DisplayRole) const override;
  bool setData (QModelIndex const&, QVariant const& value, int role = Qt::EditRole) override;
  bool removeRows (int row, int count, QModelIndex const& parent = QModelIndex {}) override;
  bool insertRows (int row, int count, QModelIndex const& parent = QModelIndex {}) override;
  Qt::DropActions supportedDropActions () const override;
  QStringList mimeTypes () const override;
  QMimeData * mimeData (QModelIndexList const&) const override;
  bool dropMimeData (QMimeData const *, Qt::DropAction, int row, int column, QModelIndex const& parent) override;

private:
  // Helper method for band validation.
  QModelIndex first_matching_band (QString const& band_name) const
  {
    // find first exact match in bands
    auto matches = bands_->match (bands_->index (0, 0)
                                  , Qt::DisplayRole
                                  , band_name
                                  , 1
                                  , Qt::MatchExactly);
    return matches.isEmpty () ? QModelIndex {} : matches.first ();
  }

  static int constexpr num_columns {3};
  static auto constexpr mime_type = "application/wsjt.antenna-descriptions";

  Bands const * bands_;
  Stations stations_;
};

StationList::StationList (Bands const * bands, QObject * parent)
  : StationList {bands, {}, parent}
{
}

StationList::StationList (Bands const * bands, Stations stations, QObject * parent)
  : QSortFilterProxyModel {parent}
  , m_ {bands, stations, parent}
{
  // setDynamicSortFilter (true);
  setSourceModel (&*m_);
  setSortRole (SortRole);
}

StationList::~StationList ()
{
}

StationList& StationList::operator = (Stations stations)
{
  m_->assign (stations);
  return *this;
}

auto StationList::stations () const -> Stations
{
  return m_->stations ();
}

QModelIndex StationList::add (Station s)
{
  return mapFromSource (m_->add (s));
}

bool StationList::remove (Station s)
{
  auto row = m_->stations ().indexOf (s);

  if (0 > row)
    {
      return false;
    }

  return removeRow (row);
}

namespace
{
  bool row_is_higher (QModelIndex const& lhs, QModelIndex const& rhs)
  {
    return lhs.row () > rhs.row ();
  }
}

bool StationList::removeDisjointRows (QModelIndexList rows)
{
  bool result {true};

  // We must work with source model indexes because we don't want row
  // removes to invalidate model indexes we haven't yet processed. We
  // achieve that by processing them in decending row order.
  for (int r = 0; r < rows.size (); ++r)
    {
      rows[r] = mapToSource (rows[r]);
    }

  // reverse sort by row
  qSort (rows.begin (), rows.end (), row_is_higher);
  Q_FOREACH (auto index, rows)
    {
      if (result && !m_->removeRow (index.row ()))
        {
          result = false;
        }
    }

  return result;
}

auto StationList::offset (Frequency f) const -> FrequencyDelta
{
  return m_->offset (f);
}


void StationList::impl::assign (Stations stations)
{
  beginResetModel ();
  std::swap (stations_, stations);
  endResetModel ();
}

QModelIndex StationList::impl::add (Station s)
{
  // Any band that isn't in the list may be added
  if (!stations_.contains (s))
    {
      auto row = stations_.size ();

      beginInsertRows (QModelIndex {}, row, row);
      stations_.append (s);
      endInsertRows ();

      return index (row, 0);
    }

  return QModelIndex {};
}

auto StationList::impl::offset (Frequency f) const -> FrequencyDelta
{
  // Lookup band for frequency
  auto band_index = bands_->find (f);
  if (band_index.isValid ())
    {
      auto band_name = band_index.data ().toString ();

      // Lookup station for band
      for (int i = 0; i < stations ().size (); ++i)
        {
          if (stations_[i].band_name_ == band_name)
            {
              return stations_[i].offset_;
            }
        }
    }

  return 0;			// no offset
}

int StationList::impl::rowCount (QModelIndex const& parent) const
{
  return parent.isValid () ? 0 : stations_.size ();
}

int StationList::impl::columnCount (QModelIndex const& parent) const
{
  return parent.isValid () ? 0 : num_columns;
}

Qt::ItemFlags StationList::impl::flags (QModelIndex const& index) const
{
  auto result = QAbstractTableModel::flags (index);

  auto row = index.row ();
  auto column = index.column ();

  if (index.isValid ()
      && row < stations_.size ()
      && column < num_columns)
    {
      if (2 == column)
        {
          result |= Qt::ItemIsEditable | Qt::ItemIsDragEnabled | Qt::ItemIsDropEnabled;
        }
      else
        {
          result |= Qt::ItemIsEditable | Qt::ItemIsDropEnabled;
        }
    }
  else
    {
      result |= Qt::ItemIsDropEnabled;
    }

  return result;
}

QVariant StationList::impl::data (QModelIndex const& index, int role) const
{
  QVariant item;

  auto row = index.row ();
  auto column = index.column ();

  if (index.isValid ()
      && row < stations_.size ())
    {
      switch (column)
        {
        case 0:			// band name
          switch (role)
            {
            case SortRole:
              {
                // Lookup band.
                auto band_index = first_matching_band (stations_.at (row).band_name_);
                // Use the sort role value of the band.
                item = band_index.data (Bands::SortRole);
              }
              break;

            case Qt::DisplayRole:
            case Qt::EditRole:
            case Qt::AccessibleTextRole:
              item = stations_.at (row).band_name_;
              break;
	      
            case Qt::ToolTipRole:
            case Qt::AccessibleDescriptionRole:
              item = tr ("Band name");
              break;

            case Qt::TextAlignmentRole:
              item = Qt::AlignHCenter + Qt::AlignVCenter;
              break;
            }
          break;

        case 1:			// frequency offset
          {
            auto frequency_offset = stations_.at (row).offset_;
            switch (role)
              {
              case Qt::AccessibleTextRole:
                item = frequency_offset;
                break;

              case SortRole:
              case Qt::DisplayRole:
              case Qt::EditRole:
                item = frequency_offset;
                break;

              case Qt::ToolTipRole:
              case Qt::AccessibleDescriptionRole:
                item = tr ("Frequency offset");
                break;

              case Qt::TextAlignmentRole:
                item = Qt::AlignRight + Qt::AlignVCenter;
                break;
              }
          }
          break;

        case 2:			// antenna description
          switch (role)
            {
            case SortRole:
            case Qt::EditRole:
            case Qt::DisplayRole:
            case Qt::AccessibleTextRole:
              item = stations_.at (row).antenna_description_;
              break;

            case Qt::ToolTipRole:
            case Qt::AccessibleDescriptionRole:
              item = tr ("Antenna description");
              break;

            case Qt::TextAlignmentRole:
              item = Qt::AlignLeft + Qt::AlignVCenter;
              break;
            }
          break;
        }
    }

  return item;
}

QVariant StationList::impl::headerData (int section, Qt::Orientation orientation, int role) const
{
  QVariant header;

  if (Qt::DisplayRole == role && Qt::Horizontal == orientation)
    {
      switch (section)
        {
        case 0: header = tr ("Band"); break;
        case 1: header = tr ("Offset"); break;
        case 2: header = tr ("Antenna Description"); break;
        }
    }
  else
    {
      header = QAbstractTableModel::headerData (section, orientation, role);
    }

  return header;
}

bool StationList::impl::setData (QModelIndex const& model_index, QVariant const& value, int role)
{
  bool changed {false};

  auto row = model_index.row ();
  auto size = stations_.size ();
  if (model_index.isValid ()
      && Qt::EditRole == role
      && row < size)
    {
      QVector<int> roles;
      roles << role;

      switch (model_index.column ())
        {
        case 0:
          {
            // Check if band name is valid.
            auto band_index = first_matching_band (value.toString ());
            if (band_index.isValid ())
              {
                stations_[row].band_name_ = band_index.data ().toString ();
                Q_EMIT dataChanged (model_index, model_index, roles);
                changed = true;
              }
          }
          break;

        case 1:
          {
            stations_[row].offset_ = value.value<FrequencyDelta> ();
            Q_EMIT dataChanged (model_index, model_index, roles);
            changed = true;
          }
          break;

        case 2:
          stations_[row].antenna_description_ = value.toString ();
          Q_EMIT dataChanged (model_index, model_index, roles);
          changed = true;
          break;
        }
    }

  return changed;
}

bool StationList::impl::removeRows (int row, int count, QModelIndex const& parent)
{
  if (0 < count && (row + count) <= rowCount (parent))
    {
      beginRemoveRows (parent, row, row + count - 1);
      for (auto r = 0; r < count; ++r)
        {
          stations_.removeAt (row);
        }
      endRemoveRows ();
      return true;
    }

  return false;
}

bool StationList::impl::insertRows (int row, int count, QModelIndex const& parent)
{
  if (0 < count)
    {
      beginInsertRows (parent, row, row + count - 1);
      for (auto r = 0; r < count; ++r)
        {
          stations_.insert (row, Station ());
        }
      endInsertRows ();
      return true;
    }

  return false;
}

Qt::DropActions StationList::impl::supportedDropActions () const
{
  return Qt::CopyAction | Qt::MoveAction;
}

QStringList StationList::impl::mimeTypes () const
{
  QStringList types;
  types << mime_type;
  types << "application/wsjt.Frequencies";
  return types;
}

QMimeData * StationList::impl::mimeData (QModelIndexList const& items) const
{
  QMimeData * mime_data = new QMimeData {};
  QByteArray encoded_data;
  QDataStream stream {&encoded_data, QIODevice::WriteOnly};

  Q_FOREACH (auto const& item, items)
    {
      if (item.isValid ())
        {
          stream << QString {data (item, Qt::DisplayRole).toString ()};
        }
    }

  mime_data->setData (mime_type, encoded_data);
  return mime_data;
}

bool StationList::impl::dropMimeData (QMimeData const * data, Qt::DropAction action, int /* row */, int /* column */, QModelIndex const& parent)
{
  if (Qt::IgnoreAction == action)
    {
      return true;
    }

  if (parent.isValid ()
      && 2 == parent.column ()
      && data->hasFormat (mime_type))
    {
      QByteArray encoded_data {data->data (mime_type)};
      QDataStream stream {&encoded_data, QIODevice::ReadOnly};
      auto dest_index = parent;
      while (!stream.atEnd ())
        {
          QString text;
          stream >> text;
          setData (dest_index, text);
          dest_index = index (dest_index.row () + 1, dest_index.column (), QModelIndex {});
        }
      return true;
    }
  else if (data->hasFormat ("application/wsjt.Frequencies"))
    {
      QByteArray encoded_data {data->data ("application/wsjt.Frequencies")};
      QDataStream stream {&encoded_data, QIODevice::ReadOnly};
      while (!stream.atEnd ())
        {
          QString frequency_string;
          stream >> frequency_string;
          auto frequency = Radio::frequency (frequency_string, 0);
          auto band_index = bands_->find (frequency);
          if (stations_.cend () == std::find_if (stations_.cbegin ()
                                                 , stations_.cend ()
                                                 , [&band_index] (Station const& s) {return s.band_name_ == band_index.data ().toString ();}))
            {
              add (Station {band_index.data ().toString (), 0, QString {}});
            }
        }

      return true;
    }

  return false;
}
