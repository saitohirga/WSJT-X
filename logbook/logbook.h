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

class LogBook
{
public:
    void init();
    void match(/*in*/ const QString call,
              /*out*/ QString &countryName,
                      bool &callWorkedBefore,
                      bool &countryWorkedBefore);
    void addAsWorked(const QString call);

private:
   CountryDat _countries;
   CountriesWorked _worked;
   ADIF _log;

   void _setAlreadyWorkedFromLog();

};

#endif // LOGBOOK_H

