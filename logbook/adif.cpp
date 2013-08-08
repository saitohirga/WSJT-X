#include "adif.h"

#include <QFile>
#include <QTextStream>

/*
<CALL:4>W1XT<BAND:3>20m<FREQ:6>14.076<GRIDSQUARE:4>DM33<MODE:4>JT65<RST_RCVD:3>-21<RST_SENT:3>-14<QSO_DATE:8>20110422<TIME_ON:4>0417<TIME_OFF:4>0424<TX_PWR:1>4<COMMENT:34>1st JT65A QSO.   Him: mag loop 20W<STATION_CALLSIGN:6>VK3ACF<MY_GRIDSQUARE:6>qf22lb<eor>
<CALL:6>IK1SOW<BAND:3>20m<FREQ:6>14.076<GRIDSQUARE:4>JN35<MODE:4>JT65<RST_RCVD:3>-19<RST_SENT:3>-11<QSO_DATE:8>20110422<TIME_ON:4>0525<TIME_OFF:4>0533<TX_PWR:1>3<STATION_CALLSIGN:6>VK3ACF<MY_GRIDSQUARE:6>qf22lb<eor>
<CALL:6:S>W4ABC> ...
*/

void ADIF::init(QString filename)
{
    _filename = filename;
    _data.clear(); 
}


QString ADIF::_extractField(const QString line, const QString fieldName)
{
    int fieldNameIndex = line.indexOf(fieldName,0,Qt::CaseInsensitive);
    if (fieldNameIndex >=0)
    {
        int closingBracketIndex = line.indexOf('>',fieldNameIndex);
        int fieldLengthIndex = line.indexOf(':',fieldNameIndex);  // find the size delimiter
        int dataTypeIndex = -1;
        if (fieldLengthIndex >= 0)
        {
          dataTypeIndex = line.indexOf(':',fieldLengthIndex+1);  // check for a second : indicating there is a data type
          if (dataTypeIndex > closingBracketIndex)
            dataTypeIndex = -1; // second : was found but it was beyond the closing >
        }

        if ((closingBracketIndex > fieldNameIndex) && (fieldLengthIndex > fieldNameIndex) && (fieldLengthIndex< closingBracketIndex))
        {
            int fieldLengthCharCount = closingBracketIndex - fieldLengthIndex -1;
            if (dataTypeIndex >= 0)
              fieldLengthCharCount -= 2; // data type indicator is always a colon followed by a single character
            QString fieldLengthString = line.mid(fieldLengthIndex+1,fieldLengthCharCount);
            int fieldLength = fieldLengthString.toInt();
            if (fieldLength > 0)
            {
              QString field = line.mid(closingBracketIndex+1,fieldLength);
              return field;
            }
       }
    }
    return "";
}



void ADIF::load()
{
    _data.clear();
    QFile inputFile(_filename);
    if (inputFile.open(QIODevice::ReadOnly))
    {
        QTextStream in(&inputFile);
        while ( !in.atEnd() )
        {
            QString line = in.readLine();
            QSO q;
            q.call = _extractField(line,"CALL:");
            q.band = _extractField(line,"BAND:");
            q.mode = _extractField(line,"MODE:");
            q.date = _extractField(line,"QSO_DATE:");
            if (q.call != "")
            _data.insert(q.call,q);
        }
        inputFile.close();
    }
}


void ADIF::add(const QString call)
{
    QSO q;
    q.call = call;
    q.band = "";     //TODO
    q.mode = "JT9";  //TODO
    q.date = "";     //TODO
    _data.insert(q.call,q);
}

// return true if in the log same band and mode (where JT65 == JT9)
bool ADIF::match(const QString call, const QString band, const QString mode)
{
    QList<QSO> qsos = _data.values(call);
    if (qsos.size()>0)
    {
        QSO q;
        foreach(q,qsos)
        {
            if (     (band.compare(q.band) == 0)
                  || (band=="")
                  || (q.band==""))
            {
                if (
                     (
                       ((mode.compare("JT65",Qt::CaseInsensitive)==0) || (mode.compare("JT9",Qt::CaseInsensitive)==0))
                       &&
                       ((q.mode.compare("JT65",Qt::CaseInsensitive)==0) || (q.mode.compare("JT9",Qt::CaseInsensitive)==0))
                     )
                        || (mode.compare(q.mode)==0)
                        || (mode=="")
                    )
                return true;
            }
        }
    }
    return false;
}    

QList<QString> ADIF::getCallList()
{
    QList<QString> p;
    QMultiHash<QString,QSO>::const_iterator i = _data.constBegin();
     while (i != _data.constEnd())
     {
         p << i.key();
         ++i;
     }
    return p;
}   
    
int ADIF::getCount()
{
    return _data.size();
}   
    
