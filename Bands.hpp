#ifndef BANDS_HPP__
#define BANDS_HPP__

#include <QAbstractTableModel>

#include "Radio.hpp"

//
// Class Bands
//
//  Encapsulates information  about amateur radio bands  as defined by
//  the  ADIF specification.  The model  is immutable.   The rows  are
//  stored in asscending order of frequency.
//
// Responsibilities
//
//  Provides  a  well  known  band  name mapped  to  lower  and  upper
//  frequency  limits.  Also  provides   a  convenience  operation  to
//  determine the band details for  any given frequency, the result of
//  which may be  invalid if the given frequency doesn't  lie within a
//  recognised band.
//
// Collaborations
//
//  Implements the QAbstractTableModel interface as an immutable table
//  where rows  are bands and  columns are band name,  lower frequency
//  limit and, upper ferquency limit respectively.
//
class Bands final
  : public QAbstractTableModel
{
public:
  explicit Bands (QObject * parent = nullptr);

  //
  // Model API
  //
  QModelIndex find (QVariant const&) const; // find band Frequency is in

  // Custom role for sorting.
  static int constexpr SortRole = Qt::UserRole;

  // Implement the QAbstractTableModel interface
  int rowCount (QModelIndex const& parent = QModelIndex {}) const override;
  int columnCount (QModelIndex const& parent = QModelIndex {}) const override;
  Qt::ItemFlags flags (QModelIndex const& = QModelIndex {}) const override;
  QVariant headerData (int section, Qt::Orientation, int = Qt::DisplayRole) const override;

  // The value return for the Qt::DisplayRole role for the root of the
  // model (invalid index) is a special string representing out of
  // band.
  //
  // All columns return a number for the custom role SortRole, this
  // number defines a strict frequency order for the rows.
  QVariant data (QModelIndex const&, int role = Qt::DisplayRole) const override;
};

#endif
