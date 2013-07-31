#include "adif.h"

#include <QFile>
#include <QTextStream>

/*
<CALL:4>W1XT<BAND:3>20m<FREQ:6>14.076<GRIDSQUARE:4>DM33<MODE:4>JT65<RST_RCVD:3>-21<RST_SENT:3>-14<QSO_DATE:8>20110422<TIME_ON:4>0417<TIME_OFF:4>0424<TX_PWR:1>4<COMMENT:34>1st JT65A QSO.   Him: mag loop 20W<STATION_CALLSIGN:6>VK3ACF<MY_GRIDSQUARE:6>qf22lb<eor>
<CALL:6>IK1SOW<BAND:3>20m<FREQ:6>14.076<GRIDSQUARE:4>JN35<MODE:4>JT65<RST_RCVD:3>-19<RST_SENT:3>-11<QSO_DATE:8>20110422<TIME_ON:4>0525<TIME_OFF:4>0533<TX_PWR:1>3<STATION_CALLSIGN:6>VK3ACF<MY_GRIDSQUARE:6>qf22lb<eor>
*/

void ADIF::init(QString filename)
{
    _filename = filename;
    _data.clear(); 
}

QString ADIF::_extractField(const QString line, const QString fieldName)
{
    int s1 = line.indexOf(fieldName,0,Qt::CaseInsensitive);
    if (s1 >=0)
    {
      int s2 = line.indexOf('>',s1);
      if (s2 >= 0)
      {
          int flsi = s1+fieldName.length();
          int flsl = s2-flsi;
          if (flsl>0)
          {
              QString fieldLengthString = line.mid(flsi,flsl);
              int fieldLength = fieldLengthString.toInt();
              QString field = line.mid(s2+1,fieldLength);
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
			_data << q;
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
    _data << q;
}

// return true if in the log same band and mode (where JT65 == JT9)
bool ADIF::match(const QString call, const QString band, const QString mode)
{
	QSO q;
	foreach(q,_data)
	{
      if (call.compare(q.call) == 0)   //TODO handle multiple log entries from same call, should this be a hash table rather than a list?
      {
		if ((band.compare(q.band) == 0) || (band=="") || (q.band==""))
		{
			if ( 
			     (
			       ((mode.compare("JT65",Qt::CaseInsensitive)==0) || (mode.compare("JT9",Qt::CaseInsensitive)==0))
			       &&
			       ((q.mode.compare("JT65",Qt::CaseInsensitive)==0) || (q.mode.compare("JT9",Qt::CaseInsensitive)==0))
			     )
			     || (mode.compare(q.mode)==0)
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
    QSO q;
    foreach(q,_data)
      p << q.call;
    return p;
}   
    
int ADIF::getCount()
{
    return _data.length();
}   
    
