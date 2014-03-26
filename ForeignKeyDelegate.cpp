#include "ForeignKeyDelegate.hpp"

#include <QComboBox>
#include <QSortFilterProxyModel>

class CandidateKeyFilter final
  : public QSortFilterProxyModel
{
public:
  explicit CandidateKeyFilter (QAbstractItemModel const * referencing_model
                               , QAbstractItemModel * referenced_model
                               , int referenced_key_column
                               , int referencing_key_role
                               , int referenced_key_role)
    : QSortFilterProxyModel {nullptr} // ForeignKeyDelegate owns us
    , referencing_ {referencing_model}
    , referencing_key_role_ {referencing_key_role}
    , referenced_key_column_ {referenced_key_column}
    , referenced_key_role_ {referenced_key_role}
  {
    setSourceModel (referenced_model);
  }

  void set_active_key (QModelIndex const& index)
  {
    active_key_ = index;
    invalidateFilter ();
  }

protected:
  bool filterAcceptsRow (int candidate_row, QModelIndex const& candidate_parent) const override
  {
    auto candidate_key = sourceModel ()->index (candidate_row, referenced_key_column_, candidate_parent).data (referenced_key_role_);

    // Include the current key.
    if (candidate_key == active_key_.data (referencing_key_role_))
      {
        return true;
      }

    // Filter out any candidates already in the referencing key rows.
    return referencing_->match (referencing_->index (0, active_key_.column ()), referencing_key_role_, candidate_key, 1, Qt::MatchExactly).isEmpty ();
  }

private:
  QAbstractItemModel const * referencing_;
  int referencing_key_role_;
  int referenced_key_column_;
  int referenced_key_role_;
  QModelIndex active_key_;
};

ForeignKeyDelegate::ForeignKeyDelegate (QAbstractItemModel const * referencing_model
                                        , QAbstractItemModel * referenced_model
                                        , int referenced_key_column
                                        , QObject * parent
                                        , int referencing_key_role
                                        , int referenced_key_role)
  : QStyledItemDelegate {parent}
  , candidate_key_filter_ {new CandidateKeyFilter {referencing_model, referenced_model, referenced_key_column, referencing_key_role, referenced_key_role}}
{
}

ForeignKeyDelegate::~ForeignKeyDelegate ()
{
}

QWidget * ForeignKeyDelegate::createEditor (QWidget * parent
                                            , QStyleOptionViewItem const& /* option */
                                            , QModelIndex const& index) const
{
  auto editor = new QComboBox {parent};
  editor->setFrame (false);
  candidate_key_filter_->set_active_key (index);
  editor->setModel (candidate_key_filter_.data ());
  return editor;
}
