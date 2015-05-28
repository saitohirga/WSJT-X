#ifndef FREQUENCY_LIST_HPP__
#define FREQUENCY_LIST_HPP__

#include "pimpl_h.hpp"

#include <QList>
#include <QSortFilterProxyModel>

#include "Radio.hpp"
#include "Modes.hpp"

class Bands;

//
// Class FrequencyList
//
//  Encapsulates a collection of frequencies.  The implementation is a
//  table  containing the  list of  Frequency type  elements which  is
//  editable  and  a  second  column  which  is  an  immutable  double
//  representation  of  the  corresponding Frequency  item  scaled  to
//  mega-Hertz.
//
//  The list is ordered.
//
// Responsibilities
//
//  Stores internally a list  of unique frequencies.  Provides methods
//  to add and delete list elements.
//
// Collaborations
//
//  Implements the QSortFilterProxyModel interface  for a list of spot
//  frequencies.
//
class FrequencyList final
  : public QSortFilterProxyModel
{
  Q_OBJECT;

public:
  using Frequency = Radio::Frequency;
  using Mode = Modes::Mode;

  struct Item
  {
    Frequency frequency_;
    Mode mode_;
  };
  using FrequencyItems = QList<Item>;

  enum Column {mode_column, frequency_column, frequency_mhz_column};

  explicit FrequencyList (Bands const *, QObject * parent = nullptr);
  ~FrequencyList ();

  // Load and store contents
  FrequencyItems frequency_list (FrequencyItems);
  FrequencyItems const& frequency_list () const;

  // Find nearest best working frequency given a frequency and mode
  QModelIndex best_working_frequency (Frequency, Mode) const;

  // Set filter
  void filter (Mode);

  // Reset
  Q_SLOT void reset_to_defaults ();

  // Model API
  QModelIndex add (Item);
  bool remove (Item);
  bool removeDisjointRows (QModelIndexList);

  // Proxy API
  bool filterAcceptsRow (int source_row, QModelIndex const& parent) const override;

  // Custom roles.
  static int constexpr SortRole = Qt::UserRole;

private:
  class impl;
  pimpl<impl> m_;
};

inline
bool operator == (FrequencyList::Item const& lhs, FrequencyList::Item const& rhs)
{
  return
    lhs.frequency_ == rhs.frequency_
    && lhs.mode_ == rhs.mode_;
}

QDataStream& operator << (QDataStream&, FrequencyList::Item const&);
QDataStream& operator >> (QDataStream&, FrequencyList::Item&);

#if !defined (QT_NO_DEBUG_STREAM)
QDebug operator << (QDebug, FrequencyList::Item const&);
#endif

Q_DECLARE_METATYPE (FrequencyList::Item);
Q_DECLARE_METATYPE (FrequencyList::FrequencyItems);

#endif
