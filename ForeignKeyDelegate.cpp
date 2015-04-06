#include "ForeignKeyDelegate.hpp"

#include <QComboBox>

#include "CandidateKeyFilter.hpp"

ForeignKeyDelegate::ForeignKeyDelegate (QAbstractItemModel const * referencing_model
                                        , QAbstractItemModel * referenced_model
                                        , int referencing_key_column
                                        , int referenced_key_column
                                        , QObject * parent
                                        , int referencing_key_role
                                        , int referenced_key_role)
  : QStyledItemDelegate {parent}
  , candidate_key_filter_ {new CandidateKeyFilter {referencing_model, referenced_model, referencing_key_column, referenced_key_column, referencing_key_role, referenced_key_role}}
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
