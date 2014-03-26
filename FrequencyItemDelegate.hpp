#ifndef FREQUENCY_ITEM_DELEGATE_HPP_
#define FREQUENCY_ITEM_DELEGATE_HPP_

#include <QStyledItemDelegate>

class QStyleOptionItemView;
class QWidget;
class QModelIndex;
class Bands;

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
  explicit FrequencyItemDelegate (Bands const * bands, QObject * parent = nullptr)
    : QStyledItemDelegate {parent}
    , bands_ {bands}
  {
  }

  QString displayText (QVariant const& value, QLocale const&) const override;
  QWidget * createEditor (QWidget * parent, QStyleOptionViewItem const&, QModelIndex const&) const override;

private:
  Bands const * bands_;
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

  QString displayText (QVariant const& value, QLocale const&) const override;
  QWidget * createEditor (QWidget * parent, QStyleOptionViewItem const&, QModelIndex const&) const override;
};

#endif
