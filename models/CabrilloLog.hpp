#ifndef CABRILLO_LOG_HPP_
#define CABRILLO_LOG_HPP_

#include <boost/core/noncopyable.hpp>
#include "Radio.hpp"
#include "pimpl_h.hpp"

class Configuration;
class QDateTime;
class QString;
class QSqlTableModel;
class QTextStream;

class CabrilloLog final
  : private boost::noncopyable
{
public:
  using Frequency = Radio::Frequency;

  explicit CabrilloLog (Configuration const *);
  ~CabrilloLog ();

  // returns false if insert fails
  bool add_QSO (Frequency, QDateTime const&, QString const& call
                , QString const& report_sent, QString const& report_received);
  bool dupe (Frequency, QString const& call) const;

  QSqlTableModel * model ();
  void reset ();
  void export_qsos (QTextStream&) const;

private:
  class impl;
  pimpl<impl> m_;
};

#endif
