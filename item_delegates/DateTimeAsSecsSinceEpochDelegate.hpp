#ifndef DATE_TIME_AS_SECS_SINCE_EPOCH_DELEGATE_HPP_
#define DATE_TIME_AS_SECS_SINCE_EPOCH_DELEGATE_HPP_

#include <memory>
#include <QStyledItemDelegate>
#include <QVariant>
#include <QLocale>
#include <QDateTime>
#include <QAbstractItemModel>
#include <QDateTimeEdit>

class DateTimeAsSecsSinceEpochDelegate final
  : public QStyledItemDelegate
{
public:
  DateTimeAsSecsSinceEpochDelegate (QObject * parent = nullptr)
    : QStyledItemDelegate {parent}
  {
  }

  static QVariant to_secs_since_epoch (QDateTime const& date_time)
  {
    return date_time.toMSecsSinceEpoch () / 1000ull;
  }

  static QDateTime to_date_time (QModelIndex const& index, int role = Qt::DisplayRole)
  {
    return to_date_time (index.model ()->data (index, role));
  }

  static QDateTime to_date_time (QVariant const& value)
  {
    return QDateTime::fromMSecsSinceEpoch (value.toULongLong () * 1000ull, Qt::UTC);
  }

  QString displayText (QVariant const& value, QLocale const& locale) const override
  {
    return locale.toString (to_date_time (value), locale.dateFormat (QLocale::ShortFormat) + " hh:mm:ss");
  }

  QWidget * createEditor (QWidget * parent, QStyleOptionViewItem const& /*option*/, QModelIndex const& /*index*/) const override
  {
    std::unique_ptr<QDateTimeEdit> editor {new QDateTimeEdit {parent}};
    editor->setDisplayFormat (parent->locale ().dateFormat (QLocale::ShortFormat) + " hh:mm:ss");
    editor->setTimeSpec (Qt::UTC); // needed because it ignores time
                                   // spec of the QDateTime that it is
                                   // set from
    return editor.release ();
  }

  void setEditorData (QWidget * editor, QModelIndex const& index) const override
  {
    static_cast<QDateTimeEdit *> (editor)->setDateTime (to_date_time (index, Qt::EditRole));
  }

  void setModelData (QWidget * editor, QAbstractItemModel * model, QModelIndex const& index) const override
  {
    model->setData (index, to_secs_since_epoch (static_cast<QDateTimeEdit *> (editor)->dateTime ()));
  }

  void updateEditorGeometry (QWidget * editor, QStyleOptionViewItem const& option, QModelIndex const& /*index*/) const override
  {
    editor->setGeometry (option.rect);
  }
};

#endif
