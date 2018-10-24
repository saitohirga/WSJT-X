/*
#Sov Mil Order of Malta:   15:  28:  EU:   41.90:   -12.43:    -1.0:  1A:
    #1A;
#Spratly Islands:          26:  50:  AS:    9.88:  -114.23:    -8.0:  1S:
    #1S,9M0,BV9S;
#Monaco:                   14:  27:  EU:   43.73:    -7.40:    -1.0:  3A:
    #3A;
#Heard Island:             39:  68:  AF:  -53.08:   -73.50:    -5.0:  VK0H:
    #=VK0IR;
#Macquarie Island:         30:  60:  OC:  -54.60:  -158.88:   -10.0:  VK0M:
    #=VK0KEV;
#Cocos-Keeling:            29:  54:  OC:  -12.15:   -96.82:    -6.5:  VK9C:
    #AX9C,AX9Y,VH9C,VH9Y,VI9C,VI9Y,VJ9C,VJ9Y,VK9C,VK9Y,VL9C,VL9Y,VM9C,VM9Y,
    #VN9C,VN9Y,VZ9C,VZ9Y,=VK9AA;
*/


#include "countrydat.h"
#include <QDir>
#include <QStandardPaths>
#include <QFile>
#include <QTextStream>
#include <QDebug>
#include "Radio.hpp"

namespace
{
  auto countryFileName = "cty.dat";
}

CountryDat::CountryDat ()
{
  QDir dataPath {QStandardPaths::writableLocation (QStandardPaths::DataLocation)};
  QFile file {dataPath.exists (countryFileName)
      ? dataPath.absoluteFilePath (countryFileName) // user override
      : QString {":/"} + countryFileName};          // or original in
                                                    // the resources FS
  if (file.open (QFile::ReadOnly))
    {
      QTextStream in {&file};
      while (!in.atEnd ())
        {
          QString line1 = in.readLine ();
          if (!in.atEnd ())
            {
              QString line2 = in.readLine ();
              auto name = extractName (line1);
              if (name.length () > 0)
                {
                  auto const& continent = line1.mid (36,2);
                  auto principalPrefix = line1.mid (69,4);
                  principalPrefix = principalPrefix.mid (0, principalPrefix.indexOf (":"));
                  name += "; " + principalPrefix + "; " + continent;
                  bool more {true};
                  QStringList prefixes;
                  while (more)
                    {
                      QStringList p = extractPrefix (line2, more);
                      prefixes += p;
                      if (more) line2 = in.readLine ();
                    }

                  Q_FOREACH (auto const& p, prefixes)
                    {
                      if (p.length() > 0) data_.insert (p, name);
                    }
                }
            }
        }
    }
}

QString CountryDat::extractName (QString const& line) const
{
    int s1 = line.indexOf(':');
    if (s1>=0)
    {
        QString name = line.mid(0,s1);
        return name;
    }
    return "";
}

void CountryDat::removeBrackets(QString& line, QString const& a, QString const& b) const
{
    int s1 = line.indexOf(a);
    while (s1 >= 0)
    {
      int s2 = line.indexOf(b);
      line = line.mid(0,s1) + line.mid(s2+1,-1);
      s1 = line.indexOf(a);
    }
}    

QStringList CountryDat::extractPrefix(QString& line, bool& more) const
{
    line = line.remove(" \n");
    line = line.replace(" ","");

    removeBrackets(line,"(",")");
    removeBrackets(line,"[","]");
    removeBrackets(line,"<",">");
    removeBrackets(line,"~","~");

    int s1 = line.indexOf(';');
    more = true;
    if (s1 >= 0)
    {
      line = line.mid(0,s1);
      more = false;
    }

    QStringList r = line.split(',');

    return r;
}

// return country name else ""
QString CountryDat::find (QString const& call) const
{
  auto const& search_string = call.toUpper ();

  // check for exact match first
  if (data_.contains ("=" + search_string))
    {
      return fixup (data_.value ("=" + search_string), search_string);
    }

  auto prefix = Radio::effective_prefix (search_string);
  auto match_candidate = prefix;
  while (match_candidate.size () >= 1)
    {
      if (data_.contains (match_candidate))
        {
          return fixup (data_.value (match_candidate), prefix);
        }
      match_candidate = match_candidate.left (match_candidate.size () - 1);
    }
  return QString {};
}

QString CountryDat::fixup (QString country, QString const& call) const
{
  //
  // deal with special rules that cty.dat does not cope with
  //

  // KG4 2x1 and 2x3 calls that map to Gitmo are mainland US not Gitmo
  if (call.startsWith ("KG4") && call.size () != 5 && call.size () != 3)
    {
      country.replace ("Guantanamo Bay; KG4; NA", "United States; K; NA");
    }
  return country;
}
