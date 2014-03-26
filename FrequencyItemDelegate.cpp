#include "FrequencyItemDelegate.hpp"

#include "Radio.hpp"
#include "FrequencyLineEdit.hpp"
#include "Bands.hpp"

QString FrequencyItemDelegate::displayText (QVariant const& value, QLocale const& locale) const
{
  auto frequency = value.value<Radio::Frequency> ();
  auto band_name = bands_->data (bands_->find (frequency));
  return Radio::pretty_frequency_MHz_string (frequency, locale) + " MHz (" + band_name.toString () + ')';
}

QWidget * FrequencyItemDelegate::createEditor (QWidget * parent
					       , QStyleOptionViewItem const& /* option */
					       , QModelIndex const& /* index */) const
{
  auto editor = new FrequencyLineEdit {parent};
  editor->setFrame (false);
  return editor;
}


QString FrequencyDeltaItemDelegate::displayText (QVariant const& value, QLocale const& locale) const
{
  return Radio::pretty_frequency_MHz_string (value.value<Radio::FrequencyDelta> (), locale) + " MHz";
}

QWidget * FrequencyDeltaItemDelegate::createEditor (QWidget * parent
					       , QStyleOptionViewItem const& /* option */
					       , QModelIndex const& /* index */) const
{
  auto editor = new FrequencyDeltaLineEdit {parent};
  editor->setFrame (false);
  return editor;
}
