/*
 * From an ADIF file and cty.dat, get a call's DXCC entity and its worked before status
 * VK3ACF July 2013
 */

#ifndef LOGBOOK_H
#define LOGBOOK_H


#include <QString>
#include <QFont>

#include "countrydat.h"
#include "countriesworked.h"
#include "adif.h"

class QDir;

class LogBook
{
public:
    void init();
    void match(/*in*/ const QString call, QString grid,
              /*out*/ QString &countryName, bool &callWorkedBefore, bool &countryWorkedBefore,
               bool &gridWorkedBefore, QString currentBand="") const;
    void addAsWorked(const QString call, const QString band, const QString mode, const QString date);

private:
   CountryDat _countries;
   CountriesWorked _worked;
   ADIF _log;

   void _setAlreadyWorkedFromLog();

};

#endif // LOGBOOK_H

