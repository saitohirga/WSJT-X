#include "Radio.hpp"

#include <cmath>

#include <QMetaType>
#include <QString>
#include <QChar>
#include <QDebug>
#include <QRegExpValidator>
#include <QDataStream>

namespace Radio
{
  namespace
  {
    struct init
    {
      init ()
      {
        qRegisterMetaType<Frequency> ("Frequency");

        qRegisterMetaType<Frequencies> ("Frequencies");
        qRegisterMetaTypeStreamOperators<Frequencies> ("Frequencies");

        qRegisterMetaType<FrequencyDelta> ("FrequencyDelta");
      }
    } static_initaializer;

    double constexpr MHz_factor {1.e6};
    int constexpr frequency_precsion {6};
  }


  Frequency frequency (QVariant const& v, int scale)
  {
    return std::llround (v.toDouble () * std::pow (10., scale));
  }

  FrequencyDelta frequency_delta (QVariant const& v, int scale)
  {
    return std::llround (v.toDouble () * std::pow (10., scale));
  }


  QString frequency_MHz_string (Frequency f, QLocale const& locale)
  {
    return locale.toString (f / MHz_factor, 'f', frequency_precsion);
  }

  QString frequency_MHz_string (FrequencyDelta d, QLocale const& locale)
  {
    return locale.toString (d / MHz_factor, 'f', frequency_precsion);
  }

  QString pretty_frequency_MHz_string (Frequency f, QLocale const& locale)
  {
    auto f_string = locale.toString (f / MHz_factor, 'f', frequency_precsion);
    return f_string.insert (f_string.size () - 3, QChar::Nbsp);
  }

  QString pretty_frequency_MHz_string (double f, int scale, QLocale const& locale)
  {
    auto f_string = locale.toString (f / std::pow (10., scale - 6), 'f', frequency_precsion);
    return f_string.insert (f_string.size () - 3, QChar::Nbsp);
  }

  QString pretty_frequency_MHz_string (FrequencyDelta d, QLocale const& locale)
  {
    auto d_string = locale.toString (d / MHz_factor, 'f', frequency_precsion);
    return d_string.insert (d_string.size () - 3, QChar::Nbsp);
  }
}
