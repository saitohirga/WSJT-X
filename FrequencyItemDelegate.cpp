#include "FrequencyItemDelegate.hpp"

#include "FrequencyLineEdit.hpp"

QWidget * FrequencyItemDelegate::createEditor (QWidget * parent
					       , QStyleOptionViewItem const& /* option */
					       , QModelIndex const& /* index */) const
{
  auto editor = new FrequencyLineEdit {parent};
  editor->setFrame (false);
  return editor;
}


QWidget * FrequencyDeltaItemDelegate::createEditor (QWidget * parent
					       , QStyleOptionViewItem const& /* option */
					       , QModelIndex const& /* index */) const
{
  auto editor = new FrequencyDeltaLineEdit {parent};
  editor->setFrame (false);
  return editor;
}
