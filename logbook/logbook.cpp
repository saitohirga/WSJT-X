#include "logbook.h"

#include <QDateTime>
#include <QDebug>
#include "countrydat.h"
#include "Configuration.hpp"

LogBook::LogBook (Configuration const * configuration)
  : config_ {configuration}
{
}

void LogBook::match (QString const& call, QString const& mode, QString const& grid,
                     QString &countryName,
                     bool &callWorkedBefore,
                     bool &countryWorkedBefore,
                     bool &gridWorkedBefore,
                     QString const& band) const
{
  if (call.length() > 0)
    {
      auto const& mode_to_check = (config_ && !config_->highlight_by_mode ()) ? QString {} : mode;
      callWorkedBefore = worked_before_.call_worked (call, mode_to_check, band);
      gridWorkedBefore = worked_before_.grid_worked(grid, mode_to_check, band);
      countryName = worked_before_.countries ().find (call);
      countryWorkedBefore = worked_before_.country_worked (countryName, mode_to_check, band);
    }
}

bool LogBook::add (QString const& call
                   , QString const& grid
                   , QString const& band
                   , QString const& mode
                   , QByteArray const& ADIF_record)
{
  return worked_before_.add (call, grid, band, mode, ADIF_record);
}

QByteArray LogBook::QSOToADIF (QString const& hisCall, QString const& hisGrid, QString const& mode,
                               QString const& rptSent, QString const& rptRcvd, QDateTime const& dateTimeOn,
                               QDateTime const& dateTimeOff, QString const& band, QString const& comments,
                               QString const& name, QString const& strDialFreq, QString const& myCall,
                               QString const& myGrid, QString const& txPower, QString const& operator_call,
                               QString const& xSent, QString const& xRcvd)
{
  QString t;
  t = "<call:" + QString::number(hisCall.length()) + ">" + hisCall;
  t += " <gridsquare:" + QString::number(hisGrid.length()) + ">" + hisGrid;
  t += " <mode:" + QString::number(mode.length()) + ">" + mode;
  t += " <rst_sent:" + QString::number(rptSent.length()) + ">" + rptSent;
  t += " <rst_rcvd:" + QString::number(rptRcvd.length()) + ">" + rptRcvd;
  t += " <qso_date:8>" + dateTimeOn.date().toString("yyyyMMdd");
  t += " <time_on:6>" + dateTimeOn.time().toString("hhmmss");
  t += " <qso_date_off:8>" + dateTimeOff.date().toString("yyyyMMdd");
  t += " <time_off:6>" + dateTimeOff.time().toString("hhmmss");
  t += " <band:" + QString::number(band.length()) + ">" + band;
  t += " <freq:" + QString::number(strDialFreq.length()) + ">" + strDialFreq;
  t += " <station_callsign:" + QString::number(myCall.length()) + ">" + myCall;
  t += " <my_gridsquare:" + QString::number(myGrid.length()) + ">" + myGrid;
  if(txPower!="") t += " <tx_pwr:" + QString::number(txPower.length()) + ">" + txPower;
  if(comments!="") t += " <comment:" + QString::number(comments.length()) + ">" + comments;
  if(name!="") t += " <name:" + QString::number(name.length()) + ">" + name;
  if(operator_call!="") t+=" <operator:" + QString::number(operator_call.length()) + ">" + operator_call;
  if(xRcvd!="") {
    QString t1="";
    if(xRcvd.split(" ").size()==2) t1=xRcvd.split(" ").at(1);
    if(t1.toInt()>0) {
      t += " <SRX:" + QString::number(t1.length()) + ">" + t1;
    } else {
      t += " <STATE:" + QString::number(t1.length()) + ">" + t1;
    }
  }
  return t.toLatin1();
}
