#include "FrequencyList.hpp"

#include <utility>

#include <QAbstractTableModel>
#include <QString>
#include <QList>
#include <QListIterator>
#include <QVector>
#include <QStringList>
#include <QMimeData>
#include <QDataStream>
#include <QByteArray>
#include <QDebug>

#include "pimpl_impl.hpp"

class FrequencyList::impl final
  : public QAbstractTableModel
{
public:
  impl (Frequencies frequencies, QObject * parent)
    : QAbstractTableModel {parent}
    , frequencies_ {frequencies}
  {
  }

  Frequencies const& frequencies () const {return frequencies_;}
  void assign (Frequencies);
  QModelIndex add (Frequency);

protected:
  // Implement the QAbstractTableModel interface
  int rowCount (QModelIndex const& parent = QModelIndex {}) const override;
  int columnCount (QModelIndex const& parent = QModelIndex {}) const override;
  Qt::ItemFlags flags (QModelIndex const& = QModelIndex {}) const override;
  QVariant data (QModelIndex const&, int role = Qt::DisplayRole) const override;
  bool setData (QModelIndex const&, QVariant const& value, int role = Qt::EditRole) override;
  QVariant headerData (int section, Qt::Orientation, int = Qt::DisplayRole) const override;
  bool removeRows (int row, int count, QModelIndex const& parent = QModelIndex {}) override;
  bool insertRows (int row, int count, QModelIndex const& parent = QModelIndex {}) override;
  QStringList mimeTypes () const override;
  QMimeData * mimeData (QModelIndexList const&) const override;

private:
  static int constexpr num_cols {2};
  static auto constexpr mime_type ="application/wsjt.Frequencies";

  Frequencies frequencies_;
};

FrequencyList::FrequencyList (QObject * parent)
  : FrequencyList {{}, parent}
{
}

FrequencyList::FrequencyList (Frequencies frequencies, QObject * parent)
  : QSortFilterProxyModel {parent}
  , m_ {frequencies, parent}
{
  // setDynamicSortFilter (true);
  setSourceModel (&*m_);
  setSortRole (SortRole);
}

FrequencyList::~FrequencyList ()
{
}

FrequencyList& FrequencyList::operator = (Frequencies frequencies)
{
  m_->assign (frequencies);
  return *this;
}

auto FrequencyList::frequencies () const -> Frequencies
{
  return m_->frequencies ();
}

QModelIndex FrequencyList::add (Frequency f)
{
  return mapFromSource (m_->add (f));
}

bool FrequencyList::remove (Frequency f)
{
  auto row = m_->frequencies ().indexOf (f);

  if (0 > row)
    {
      return false;
    }

  return m_->removeRow (row);
}

namespace
{
  bool row_is_higher (QModelIndex const& lhs, QModelIndex const& rhs)
  {
    return lhs.row () > rhs.row ();
  }
}

bool FrequencyList::removeDisjointRows (QModelIndexList rows)
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


void FrequencyList::impl::assign (Frequencies frequencies)
{
  beginResetModel ();
  std::swap (frequencies_, frequencies);
  endResetModel ();
}

QModelIndex FrequencyList::impl::add (Frequency f)
{
  // Any Frequency that isn't in the list may be added
  if (!frequencies_.contains (f))
    {
      auto row = frequencies_.size ();

      beginInsertRows (QModelIndex {}, row, row);
      frequencies_.append (f);
      endInsertRows ();

      return index (row, 0);
    }

  return QModelIndex {};
}

int FrequencyList::impl::rowCount (QModelIndex const& parent) const
{
  return parent.isValid () ? 0 : frequencies_.size ();
}

int FrequencyList::impl::columnCount (QModelIndex const& parent) const
{
  return parent.isValid () ? 0 : num_cols;
}

Qt::ItemFlags FrequencyList::impl::flags (QModelIndex const& index) const
{
  auto result = QAbstractTableModel::flags (index) | Qt::ItemIsDropEnabled;

  auto row = index.row ();
  auto column = index.column ();

  if (index.isValid ()
      && row < frequencies_.size ()
      && column < num_cols)
    {
      switch (column)
        {
        case 0:
          result |= Qt::ItemIsEditable | Qt::ItemIsDragEnabled | Qt::ItemIsDropEnabled;
          break;

        case 1:
          result |= Qt::ItemIsDragEnabled;
          break;
        }
    }

  return result;
}

QVariant FrequencyList::impl::data (QModelIndex const& index, int role) const
{
  QVariant item;

  auto row = index.row ();
  auto column = index.column ();

  if (index.isValid ()
      && row < frequencies_.size ()
      && column < num_cols)
    {
      auto frequency = frequencies_.at (row);

      switch (column)
        {
        case 0:
          switch (role)
            {
            case SortRole:
            case Qt::DisplayRole:
            case Qt::EditRole:
            case Qt::AccessibleTextRole:
              item = frequency;
              break;
	      
            case Qt::ToolTipRole:
            case Qt::AccessibleDescriptionRole:
              item = tr ("Frequency");
              break;

            case Qt::TextAlignmentRole:
              item = Qt::AlignRight + Qt::AlignVCenter;
              break;
            }
          break;

        case 1:
          switch (role)
            {
            case Qt::DisplayRole:
            case Qt::EditRole:
            case Qt::AccessibleTextRole:
              item = static_cast<double> (frequency / 1.e6);
              break;

            case SortRole:	// use the underlying Frequency value
              item = frequency;
              break;
	      
            case Qt::ToolTipRole:
            case Qt::AccessibleDescriptionRole:
              item = tr ("Frequency MHz");
              break;

            case Qt::TextAlignmentRole:
              item = Qt::AlignRight + Qt::AlignVCenter;
              break;
            }
          break;
        }
    }

  return item;
}

bool FrequencyList::impl::setData (QModelIndex const& model_index, QVariant const& value, int role)
{
  bool changed {false};

  auto row = model_index.row ();
  if (model_index.isValid ()
      && Qt::EditRole == role
      && row < frequencies_.size ()
      && 0 == model_index.column ()
      && value.canConvert<Frequency> ())
    {
      auto frequency = value.value<Frequency> ();
      auto original_frequency = frequencies_.at (row);
      if (frequency != original_frequency)
        {
          frequencies_.replace (row, frequency);
          Q_EMIT dataChanged (model_index, index (model_index.row (), 1), QVector<int> {} << role);
        }
      changed = true;
    }

  return changed;
}

QVariant FrequencyList::impl::headerData (int section, Qt::Orientation orientation, int role) const
{
  QVariant header;

  if (Qt::DisplayRole == role
      && Qt::Horizontal == orientation
      && section < num_cols)
    {
      switch (section)
        {
        case 0: header = tr ("Frequency"); break;
        case 1: header = tr ("Frequency (MHz)"); break;
        }
    }
  else
    {
      header = QAbstractTableModel::headerData (section, orientation, role);
    }

  return header;
}

bool FrequencyList::impl::removeRows (int row, int count, QModelIndex const& parent)
{
  if (0 < count && (row + count) <= rowCount (parent))
    {
      beginRemoveRows (parent, row, row + count - 1);
      for (auto r = 0; r < count; ++r)
        {
          frequencies_.removeAt (row);
        }
      endRemoveRows ();
      return true;
    }

  return false;
}

bool FrequencyList::impl::insertRows (int row, int count, QModelIndex const& parent)
{
  if (0 < count)
    {
      beginInsertRows (parent, row, row + count - 1);
      for (auto r = 0; r < count; ++r)
        {
          frequencies_.insert (row, Frequency {});
        }
      endInsertRows ();
      return true;
    }

  return false;
}

QStringList FrequencyList::impl::mimeTypes () const
{
  QStringList types;
  types << mime_type;
  return types;
}

QMimeData * FrequencyList::impl::mimeData (QModelIndexList const& items) const
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
