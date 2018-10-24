#ifndef WORKWED_BEFORE_HPP_
#define WORKWED_BEFORE_HPP_

#include <boost/core/noncopyable.hpp>
#include "pimpl_h.hpp"

class CountryDat;
class QString;
class QByteArray;

class WorkedBefore final
  : private boost::noncopyable
{
public:
  explicit WorkedBefore ();
  ~WorkedBefore ();

  QString const& path () const;
  CountryDat const& countries () const;
  bool add (QString const& call
            , QString const& grid
            , QString const& band
            , QString const& mode
            , QByteArray const& ADIF_record);
  bool country_worked (QString const& call, QString const& mode, QString const& band) const;
  bool grid_worked (QString const& grid, QString const& mode, QString const& band) const;
  bool call_worked (QString const& call, QString const& mode, QString const& band) const;

private:
  class impl;
  pimpl<impl> m_;
};

#endif
