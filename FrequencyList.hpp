#ifndef FREQUENCY_LIST_HPP__
#define FREQUENCY_LIST_HPP__

#include "pimpl_h.hpp"

#include <QSortFilterProxyModel>

#include "Radio.hpp"

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
public:
  using Frequency = Radio::Frequency;
  using Frequencies = Radio::Frequencies;

  explicit FrequencyList (QObject * parent = nullptr);
  explicit FrequencyList (Frequencies, QObject * parent = nullptr);
  ~FrequencyList ();

  // Load and store contents
  FrequencyList& operator = (Frequencies);
  Frequencies frequencies () const;

  // Model API
  QModelIndex add (Frequency);
  bool remove (Frequency);
  bool removeDisjointRows (QModelIndexList);

  // Custom roles.
  static int constexpr SortRole = Qt::UserRole;

private:
  class impl;
  pimpl<impl> m_;
};

#endif
