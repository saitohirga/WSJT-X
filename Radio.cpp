#include "Radio.hpp"

#include <cmath>

#include <QString>
#include <QChar>
#include <QDebug>
#include <QDataStream>
#include <QRegularExpression>

namespace Radio
{
  namespace
  {
    double constexpr MHz_factor {1.e6};
    int constexpr frequency_precsion {6};

    // very loose validation - callsign must contain a letter next to
    // a number
    QRegularExpression valid_callsign_regexp {R"(\d[[:alpha:]]|[[:alpha:]]\d)"};
  }


  Frequency frequency (QVariant const& v, int scale, QLocale const& locale)
  {
    double value {0};
    if (QVariant::String == v.type ())
      {
        value = locale.toDouble (v.value<QString> ());
      }
    else
      {
        value = v.toDouble ();
      }
    return std::llround (value * std::pow (10., scale));
  }

  FrequencyDelta frequency_delta (QVariant const& v, int scale, QLocale const& locale)
  {
    double value {0};
    if (QVariant::String == v.type ())
      {
        value = locale.toDouble (v.value<QString> ());
      }
    else
      {
        value = v.toDouble ();
      }
    return std::llround (value * std::pow (10., scale));
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

  bool is_callsign (QString const& callsign)
  {
    return callsign.contains (valid_callsign_regexp);
  }

  bool is_compound_callsign (QString const& callsign)
  {
    return callsign.contains ('/');
  }

  // split on first '/' and return the larger portion or the whole if
  // there is no '/'
  QString base_callsign (QString callsign)
  {
    auto slash_pos = callsign.indexOf ('/');
    if (slash_pos >= 0)
      {
        auto right_size = callsign.size () - slash_pos - 1;
        if (right_size>= slash_pos)
          {
            callsign = callsign.mid (slash_pos + 1);
          }
        else
          {
            callsign = callsign.left (slash_pos);
          }
      }
    return callsign;
  }
}
