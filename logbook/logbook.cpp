#include "logbook.h"
#include <QDebug>
#include <QFontMetrics>


void LogBook::init()
{
    const QString logFilename = "wsjtx_log.adi";    //TODO get from user
    const QString countryDataFilename = "cty.dat";  //TODO get from user

    _countries.init(countryDataFilename);
    _countries.load();

    _worked.init(_countries.getCountryNames());

    _log.init(logFilename);
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
//    match(/*in*/call, /*out*/ countryName,callWorkedBefore,countryWorkedBefore);
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

void LogBook::match(/*in*/const QString call,
                  /*out*/ QString &countryName,
                          bool &callWorkedBefore,
                          bool &countryWorkedBefore)
{
    if (call.length() > 0)
    {
        QString currentMode = "JT9"; // JT65 == JT9 in ADIF::match()
        QString currentBand = "";  // match any band
        callWorkedBefore = _log.match(call,currentBand,currentMode);
        countryName = _countries.find(call);
        if (countryName.length() > 0)  //  country was found
          countryWorkedBefore = _worked.getHasWorked(countryName);
        else
        {
          countryName = "where?"; //error: prefix not found
          countryWorkedBefore = false;
        }
    }
    //qDebug() << "Logbook:" << call << ":" << countryName << "Cty B4:" << countryWorkedBefore << "call B4:" << callWorkedBefore;
}

void LogBook::addAsWorked(const QString call)
{
    //qDebug() << "adding " << call << " as worked";
    _log.add(call);
    QString countryName = _countries.find(call);
    if (countryName.length() > 0)
        _worked.setAsWorked(countryName);
}



