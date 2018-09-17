#include "logbook.h"
#include <QDebug>
#include <QFontMetrics>
#include <QStandardPaths>
#include <QDir>

namespace
{
  auto logFileName = "wsjtx_log.adi";
  auto countryFileName = "cty.dat";
}

void LogBook::init()
{
  QDir dataPath {QStandardPaths::writableLocation (QStandardPaths::DataLocation)};
  QString countryDataFilename;
  if (dataPath.exists (countryFileName))
    {
      // User override
      countryDataFilename = dataPath.absoluteFilePath (countryFileName);
    }
  else
    {
      countryDataFilename = QString {":/"} + countryFileName;
    }

  _countries.init(countryDataFilename);
  _countries.load();

  _worked.init(_countries.getCountryNames());

  _log.init(dataPath.absoluteFilePath (logFileName));
  _log.load();

  _setAlreadyWorkedFromLog();

  /*
    int QSOcount = _log.getCount();
    int count = _worked.getWorkedCount();
    qDebug() << QSOcount << "QSOs and" << count << "countries worked in file" << logFilename;
  */

  //    QString call = "ok1ct";
  //    QString countryName;
  //    bool callWorkedBefore,countryWorkedBefore;
  //    match(/*in*/call,grid, /*out*/ countryName,callWorkedBefore,countryWorkedBefore);
  //    qDebug() << countryName;

}


void LogBook::_setAlreadyWorkedFromLog()
{
  QList<QString> calls = _log.getCallList();
  QString c;
  foreach(c,calls)
    {
      QString countryName = _countries.find(c);
      if (countryName.length() > 0)
        {
          _worked.setAsWorked(countryName);
          //qDebug() << countryName << " worked " << c;
        }
    }
}

void LogBook::match(/*in*/const QString call,QString grid,
                    /*out*/ QString &countryName,
                    bool &callWorkedBefore,
                    bool &countryWorkedBefore,
                    bool &gridWorkedBefore,
                    QString currentBand) const
{
//  if(currentBand=="") qDebug() << "aa" << grid;
//  if(currentBand!="") qDebug() << "bb" << grid << currentBand;

  if (call.length() > 0) {
    QString currentMode = "JT9"; // JT65 == JT9 == FT8 in ADIF::match()
//    QString currentBand = "";  // match any band
    callWorkedBefore = _log.match(call,currentBand,currentMode);
    gridWorkedBefore = _log.match(grid,currentBand,currentMode);
    countryName = _countries.find(call);

    if (countryName.length() > 0) { //  country was found
      countryWorkedBefore = _worked.getHasWorked(countryName);
    } else {
      countryName = "where?"; //error: prefix not found
      countryWorkedBefore = false;
    }
//    qDebug() << "Logbook:" << call << currentBand << callWorkedBefore << countryName << countryWorkedBefore;
  }
}

void LogBook::addAsWorked(const QString call, const QString grid, const QString band,
                          const QString mode, const QString date)
{
  //qDebug() << "adding " << call << " as worked";
  _log.add(call,grid,band,mode,date);
  QString countryName = _countries.find(call);
  if (countryName.length() > 0)
    _worked.setAsWorked(countryName);
}



