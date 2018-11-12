#ifndef WORKWED_BEFORE_HPP_
#define WORKWED_BEFORE_HPP_

#include <boost/core/noncopyable.hpp>
#include "AD1CCty.hpp"
#include "pimpl_h.hpp"

class CountryDat;
class QString;
class QByteArray;

class WorkedBefore final
  : private boost::noncopyable
{
public:
  using Continent = AD1CCty::Continent;

  explicit WorkedBefore ();
  ~WorkedBefore ();

  QString const& path () const;
  AD1CCty const& countries () const;
  bool add (QString const& call
            , QString const& grid
            , QString const& band
            , QString const& mode
            , QByteArray const& ADIF_record);
  bool country_worked (QString const& call, QString const& mode, QString const& band) const;
  bool grid_worked (QString const& grid, QString const& mode, QString const& band) const;
  bool call_worked (QString const& call, QString const& mode, QString const& band) const;
  bool continent_worked (Continent continent, QString const& mode, QString const& band) const;
  bool CQ_zone_worked (int CQ_zone, QString const& mode, QString const& band) const;
  bool ITU_zone_worked (int ITU_zone, QString const& mode, QString const& band) const;

private:
  class impl;
  pimpl<impl> m_;
};

#endif
