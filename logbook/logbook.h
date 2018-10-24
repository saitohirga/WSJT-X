/*
 * From an ADIF file and cty.dat, get a call's DXCC entity and its worked before status
 * VK3ACF July 2013
 */

#ifndef LOG_BOOK_H_
#define LOG_BOOK_H_

#include <boost/core/noncopyable.hpp>
#include <QString>

#include "WorkedBefore.hpp"

class Configuration;
class QByteArray;
class QDateTime;

class LogBook final
  : private boost::noncopyable
{
 public:
  LogBook (Configuration const *);
  QString const& path () const {return worked_before_.path ();}
  bool add (QString const& call
            , QString const& grid
            , QString const& band
            , QString const& mode
            , QByteArray const& ADIF_record);
  CountryDat const& countries () const {return worked_before_.countries ();}
  void match (QString const& call, QString const& mode, QString const& grid,
              QString &countryName, bool &callWorkedBefore, bool &countryWorkedBefore,
              bool &gridWorkedBefore, QString const& currentBand = QString {}) const;
  static QByteArray QSOToADIF (QString const& hisCall, QString const& hisGrid, QString const& mode,
                               QString const& rptSent, QString const& rptRcvd, QDateTime const& dateTimeOn,
                               QDateTime const& dateTimeOff, QString const& band, QString const& comments,
                               QString const& name, QString const& strDialFreq, QString const& myCall,
                               QString const& m_myGrid, QString const& m_txPower, QString const& operator_call,
                               QString const& xSent, QString const& xRcvd);

 private:
  Configuration const * config_;
  WorkedBefore worked_before_;
};

#endif
