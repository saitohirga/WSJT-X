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

#include "Bands.hpp"
#include "pimpl_impl.hpp"

namespace
{
  FrequencyList::FrequencyItems const default_frequency_list =
    {
      {136000, Modes::WSPR},
      {136130, Modes::JT65},
      {474200, Modes::JT65},
      {474200, Modes::JT9},
      {474200, Modes::WSPR},
      {1836600, Modes::WSPR},
      {1838000, Modes::JT65},
      {1840000, Modes::JT9},
      {3576000, Modes::JT65},
      {3578000, Modes::JT9},
      {3592600, Modes::WSPR},
      {5357000, Modes::JT65},
      {5287200, Modes::WSPR},
      {7038600, Modes::WSPR},
      {7076000, Modes::JT65},
      {7078000, Modes::JT9},
      {10138000, Modes::JT65},
      {10138700, Modes::WSPR},
      {10140000, Modes::JT9},
      {14095600, Modes::WSPR},
      {14076000, Modes::JT65},
      {14078000, Modes::JT9},
      {18102000, Modes::JT65},
      {18104000, Modes::JT9},
      {18104600, Modes::WSPR},
      {21076000, Modes::JT65},
      {21078000, Modes::JT9},
      {21094600, Modes::WSPR},
      {24917000, Modes::JT65},
      {24919000, Modes::JT9},
      {24924600, Modes::WSPR},
      {28076000, Modes::JT65},
      {28078000, Modes::JT9},
      {28124600, Modes::WSPR},
      {50276000, Modes::JT65},
      {50293000, Modes::WSPR},
      {70091000, Modes::JT65},
      {70091000, Modes::WSPR},
      {144000000, Modes::JT4},
      {144489000, Modes::JT65},
      {144489000, Modes::WSPR},
      {222000000, Modes::JT4},
      {222000000, Modes::JT65},
      {432000000, Modes::JT4},
      {432000000, Modes::JT65},
      {432300000, Modes::WSPR},
      {902000000, Modes::JT4},
      {902000000, Modes::JT65},
      {1296000000, Modes::JT4},
      {1296000000, Modes::JT65},
      {1296500000, Modes::WSPR},
      {2301000000, Modes::JT4},
      {2301000000, Modes::JT65},
      {2304000000, Modes::JT4},
      {2304000000, Modes::JT65},
      {2320000000, Modes::JT4},
      {2320000000, Modes::JT65},
      {3400000000, Modes::JT4},
      {3400000000, Modes::JT65},
      {3456000000, Modes::JT4},
      {3456000000, Modes::JT65},
      {5760000000, Modes::JT4},
      {5760000000, Modes::JT65},
      {10368000000, Modes::JT4},
      {10368000000, Modes::JT65},
      {24048000000, Modes::JT4},
      {24048000000, Modes::JT65},
    };
}

#if !defined (QT_NO_DEBUG_STREAM)
QDebug operator << (QDebug debug, FrequencyList::Item const& item)
{
  debug.nospace () << "FrequencyItem("
                   << item.frequency_ << ", "
                   << item.mode_ << ')';
  return debug.space ();
}
#endif

QDataStream& operator << (QDataStream& os, FrequencyList::Item const& item)
{
  return os << item.frequency_
            << item.mode_;
}

QDataStream& operator >> (QDataStream& is, FrequencyList::Item& item)
{
  return is >> item.frequency_
            >> item.mode_;
}

class FrequencyList::impl final
  : public QAbstractTableModel
{
public:
  impl (Bands const * bands, QObject * parent)
    : QAbstractTableModel {parent}
    , bands_ {bands}
    , mode_filter_ {Modes::NULL_MODE}
  {
  }

  FrequencyItems frequency_list (FrequencyItems);
  QModelIndex add (Item);

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

  static int constexpr num_cols {3};
  static auto constexpr mime_type ="application/wsjt.Frequencies";

  Bands const * bands_;
  FrequencyItems frequency_list_;
  Mode mode_filter_;
};

FrequencyList::FrequencyList (Bands const * bands, QObject * parent)
  : QSortFilterProxyModel {parent}
  , m_ {bands, parent}
{
  setSourceModel (&*m_);
  setSortRole (SortRole);
}

FrequencyList::~FrequencyList ()
{
}

auto FrequencyList::frequency_list (FrequencyItems frequency_list) -> FrequencyItems
{
  return m_->frequency_list (frequency_list);
}

auto FrequencyList::frequency_list () const -> FrequencyItems const&
{
  return m_->frequency_list_;
}

QModelIndex FrequencyList::best_working_frequency (Frequency f, Mode mode) const
{
  auto const& target_band = m_->bands_->find (f);
  if (target_band != m_->bands_->out_of_band ())
    {
      // find a frequency in the same band that is allowed for the
      // target mode
      for (int row = 0; row < rowCount (); ++row)
        {
          auto const& source_row = mapToSource (index (row, 0)).row ();
          auto const& band = m_->bands_->find (m_->frequency_list_[source_row].frequency_);
          if (band->name_ == target_band->name_)
            {
              if (m_->frequency_list_[source_row].mode_ == mode)
                {
                  return index (row, 0);
                }
            }
        }
    }
  return QModelIndex {};
}

void FrequencyList::reset_to_defaults ()
{
  m_->frequency_list (default_frequency_list);
}

QModelIndex FrequencyList::add (Item f)
{
  return mapFromSource (m_->add (f));
}

bool FrequencyList::remove (Item f)
{
  auto row = m_->frequency_list_.indexOf (f);

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

void FrequencyList::filter (Mode mode)
{
  m_->mode_filter_ = mode;
  invalidateFilter ();
}

bool FrequencyList::filterAcceptsRow (int source_row, QModelIndex const& /* parent */) const
{
  bool result {true};
  if (m_->mode_filter_ != Modes::NULL_MODE)
    {
      auto const& item = m_->frequency_list_[source_row];
      result = item.mode_ == Modes::NULL_MODE || m_->mode_filter_ == item.mode_;
    }
  return result;
}


auto FrequencyList::impl::frequency_list (FrequencyItems frequency_list) -> FrequencyItems
{
  beginResetModel ();
  std::swap (frequency_list_, frequency_list);
  endResetModel ();
  return frequency_list;
}

QModelIndex FrequencyList::impl::add (Item f)
{
  // Any Frequency that isn't in the list may be added
  if (!frequency_list_.contains (f))
    {
      auto row = frequency_list_.size ();

      beginInsertRows (QModelIndex {}, row, row);
      frequency_list_.append (f);
      endInsertRows ();

      return index (row, 0);
    }
  return QModelIndex {};
}

int FrequencyList::impl::rowCount (QModelIndex const& parent) const
{
  return parent.isValid () ? 0 : frequency_list_.size ();
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
      && row < frequency_list_.size ()
      && column < num_cols)
    {
      if (frequency_mhz_column != column)
        {
          result |= Qt::ItemIsEditable | Qt::ItemIsDragEnabled;
        }
    }
  return result;
}

QVariant FrequencyList::impl::data (QModelIndex const& index, int role) const
{
  QVariant item;

  auto const& row = index.row ();
  auto const& column = index.column ();

  if (index.isValid ()
      && row < frequency_list_.size ()
      && column < num_cols)
    {
      auto const& frequency_item = frequency_list_.at (row);
      switch (column)
        {
        case mode_column:
          switch (role)
            {
            case SortRole:
            case Qt::DisplayRole:
            case Qt::EditRole:
            case Qt::AccessibleTextRole:
              item = Modes::name (frequency_item.mode_);
              break;

            case Qt::ToolTipRole:
            case Qt::AccessibleDescriptionRole:
              item = tr ("Mode");
              break;

            case Qt::TextAlignmentRole:
              item = Qt::AlignHCenter + Qt::AlignVCenter;
              break;
            }
          break;

        case frequency_column:
          switch (role)
            {
            case SortRole:
            case Qt::EditRole:
            case Qt::AccessibleTextRole:
              item = frequency_item.frequency_;
              break;

            case Qt::DisplayRole:
              {
                auto const& band = bands_->find (frequency_item.frequency_);
                item = Radio::pretty_frequency_MHz_string (frequency_item.frequency_) + " MHz (" + band->name_ + ')';
              }
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

        case frequency_mhz_column:
          switch (role)
            {
            case Qt::EditRole:
            case Qt::AccessibleTextRole:
              item = frequency_item.frequency_ / 1.e6;
              break;

            case Qt::DisplayRole:
              {
                auto const& band = bands_->find (frequency_item.frequency_);
                item = Radio::pretty_frequency_MHz_string (frequency_item.frequency_) + " MHz (" + band->name_ + ')';
              }
              break;

            case Qt::ToolTipRole:
            case Qt::AccessibleDescriptionRole:
              item = tr ("Frequency (MHz)");
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

  auto const& row = model_index.row ();
  if (model_index.isValid ()
      && Qt::EditRole == role
      && row < frequency_list_.size ())
    {
      QVector<int> roles;
      roles << role;

      auto& item = frequency_list_[row];
      switch (model_index.column ())
        {
        case mode_column:
          if (value.canConvert<Mode> ())
            {
              auto mode = Modes::value (value.toString ());
              if (mode != item.mode_)
                {
                  item.mode_ = mode;
                  Q_EMIT dataChanged (model_index, model_index, roles);
                  changed = true;
                }
            }
          break;

        case frequency_column:
          if (value.canConvert<Frequency> ())
            {
              auto frequency = value.value<Frequency> ();
              if (frequency != item.frequency_)
                {
                  item.frequency_ = frequency;
                  // mark derived column (1) changed as well
                  Q_EMIT dataChanged (index (model_index.row (), 1), model_index, roles);
                  changed = true;
                }
            }
          break;
        }
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
        case mode_column: header = tr ("Mode"); break;
        case frequency_column: header = tr ("Frequency"); break;
        case frequency_mhz_column: header = tr ("Frequency (MHz)"); break;
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
          frequency_list_.removeAt (row);
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
          frequency_list_.insert (row, Item {0, Mode::NULL_MODE});
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
      if (item.isValid () && frequency_column == item.column ())
        {
          stream << QString {data (item, Qt::DisplayRole).toString ()};
        }
    }

  mime_data->setData (mime_type, encoded_data);
  return mime_data;
}
