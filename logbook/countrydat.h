/*
 * Reads cty.dat file
 * Establishes a map between prefixes and their country names
 * VK3ACF July 2013
 */

#ifndef COUNTRY_DAT_H_
#define COUNTRY_DAT_H_

#include <boost/core/noncopyable.hpp>
#include <QString>
#include <QHash>

class CountryDat final
  : private boost::noncopyable
{
 public:
  CountryDat ();
  QString find (QString const& call) const; // return country name or ""
   
private:
  QString extractName (QString const&  line) const;
  void removeBrackets (QString& line, QString const& a, QString const& b) const;
  QStringList extractPrefix (QString& line, bool& more) const;
  QString fixup (QString country, QString const& call) const;

  QHash<QString, QString> data_;
};

#endif
