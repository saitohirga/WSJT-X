#ifndef FREQUENCY_ITEM_DELEGATE_HPP_
#define FREQUENCY_ITEM_DELEGATE_HPP_

#include <QStyledItemDelegate>

//
// Class FrequencyItemDelegate
//
//	Item delegate for displaying and editing a Frequency item in a
//	view that uses a FrequencyLineEdit as an item delegate for the
//	edit role.
//
class FrequencyItemDelegate final
  : public QStyledItemDelegate
{
public:
  explicit FrequencyItemDelegate (QObject * parent = nullptr)
    : QStyledItemDelegate {parent}
  {
  }

  QWidget * createEditor (QWidget * parent, QStyleOptionViewItem const&, QModelIndex const&) const override;
};


//
// Class FrequencyDeltaItemDelegate
//
//	Item delegate for displaying and editing a FrequencyDelta item
//	in a view that uses a FrequencyDeltaLineEdit as an item
//	delegate for the edit role.
//
class FrequencyDeltaItemDelegate final
  : public QStyledItemDelegate
{
public:
  explicit FrequencyDeltaItemDelegate (QObject * parent = nullptr)
    : QStyledItemDelegate {parent}
  {
  }

  QWidget * createEditor (QWidget * parent, QStyleOptionViewItem const&, QModelIndex const&) const override;
};

#endif
