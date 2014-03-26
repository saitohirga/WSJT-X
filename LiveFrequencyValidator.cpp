#include "LiveFrequencyValidator.hpp"

#include <QLocale>
#include <QString>
#include <QComboBox>
#include <QLineEdit>

#include "Bands.hpp"
#include "FrequencyList.hpp"

#include "moc_LiveFrequencyValidator.cpp"

LiveFrequencyValidator::LiveFrequencyValidator (QComboBox * combo_box
                                                , Bands const * bands
                                                , FrequencyList const * frequencies
                                                , QWidget * parent)
  : QRegExpValidator {
  QRegExp {				// frequency in MHz or band
    bands->data (QModelIndex {}).toString () // out of band string
      + QString {R"(|((\d{0,6}(\)"}		 // up to 6 digits
    + QLocale {}.decimalPoint () // (followed by decimal separator
                   + R"(\d{0,2})?)([Mm]{1,2}|([Cc][Mm])))|(\d{0,4}(\)" // followed by up to 2 digits and either 'm' or 'cm' or 'mm' (case insensitive))
                   + QLocale {}.decimalPoint () // or a decimal separator
                                  + R"(\d{0,6})?))"	       //  followed by up to 6 digits
                                  }
  , parent
      }
  , bands_ {bands}
  , frequencies_ {frequencies}
  , combo_box_ {combo_box}
{
}

auto LiveFrequencyValidator::validate (QString& input, int& pos) const -> State
{
  auto state = QRegExpValidator::validate (input, pos);

  // by never being Acceptable we force fixup calls on ENTER or
  // losing focus
  return Acceptable == state ? Intermediate : state;
}

void LiveFrequencyValidator::fixup (QString& input) const
{
  QRegExpValidator::fixup (input);

  auto out_of_band = bands_->data (QModelIndex {}).toString ();

  if (!out_of_band.startsWith (input))
    {
      if (input.contains ('m', Qt::CaseInsensitive))
	{
	  input = input.toLower ();

	  QVector<QVariant> frequencies;
	  for (int r = 0; r < frequencies_->rowCount (); ++r)
	    {
	      auto frequency = frequencies_->index (r, 0).data ();
	      auto band_index = bands_->find (frequency);
	      if (band_index.data ().toString () == input)
		{
		  frequencies << frequency;
		}
	    }
	  if (!frequencies.isEmpty ())
	    {
	      Q_EMIT valid (frequencies.first ().value<Frequency> ());
	    }
	  else
	    {
	      input = QString {};
	    }
	}
      else
	{
	  // frequency input
	  auto f = Radio::frequency (input, 6);
	  input = bands_->data (bands_->find (f)).toString ();
	  Q_EMIT valid (f);
	}

      if (out_of_band == input)
	{
	  combo_box_->lineEdit ()->setStyleSheet ("QLineEdit {color: yellow; background-color : red;}");
	}
      else
	{
	  combo_box_->lineEdit ()->setStyleSheet ({});
	}
      combo_box_->setCurrentText (input);
    }
}
