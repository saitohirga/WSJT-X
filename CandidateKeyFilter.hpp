#ifndef CANDIDATE_KEY_FILTER_HPP_
#define CANDIDATE_KEY_FILTER_HPP_

#include <QSortFilterProxyModel>
#include <QModelIndex>

#include "pimpl_h.hpp"

class QAbstractItemModel;

class CandidateKeyFilter final
  : public QSortFilterProxyModel
{
public:
  explicit CandidateKeyFilter (QAbstractItemModel const * referencing_model
                               , QAbstractItemModel * referenced_model
                               , int referencing_key_column = 0
                               , int referenced_key_column = 0
                               , int referencing_key_role = Qt::EditRole
                               , int referenced_key_role = Qt::EditRole);
  ~CandidateKeyFilter ();

  // this key is not to be filtered, usually because we want to allow
  // it since we are editing the row that contains it this it is valid
  // even though it is in use
  void set_active_key (QModelIndex const& index = QModelIndex {});

protected:
  bool filterAcceptsRow (int candidate_row, QModelIndex const& candidate_parent) const override;

private:
  class impl;
  pimpl<impl> m_;
};

#endif
