#include "adif.h"

#include <QFile>
#include <QTextStream>
#include <QDateTime>
#include <QDebug>

/*
<CALL:4>W1XT<BAND:3>20m<FREQ:6>14.076<GRIDSQUARE:4>DM33<MODE:4>JT65<RST_RCVD:3>-21<RST_SENT:3>-14<QSO_DATE:8>20110422<TIME_ON:6>041712<TIME_OFF:6>042435<TX_PWR:1>4<COMMENT:34>1st JT65A QSO.   Him: mag loop 20W<STATION_CALLSIGN:6>VK3ACF<MY_GRIDSQUARE:6>qf22lb<eor>
<CALL:6>IK1SOW<BAND:3>20m<FREQ:6>14.076<GRIDSQUARE:4>JN35<MODE:4>JT65<RST_RCVD:3>-19<RST_SENT:3>-11<QSO_DATE:8>20110422<TIME_ON:6>052501<TIME_OFF:6>053359<TX_PWR:1>3<STATION_CALLSIGN:6>VK3ACF<MY_GRIDSQUARE:6>qf22lb<eor>
<CALL:6:S>W4ABC> ...
*/

void ADIF::init(QString const& filename)
{
    _filename = filename;
    _data.clear();
    _data2.clear();
}


QString ADIF::extractField(QString const& record, QString const& fieldName) const
{
    int fieldNameIndex = record.indexOf ('<' + fieldName + ':', 0, Qt::CaseInsensitive);
    if (fieldNameIndex >=0)
    {
        int closingBracketIndex = record.indexOf('>',fieldNameIndex);
        int fieldLengthIndex = record.indexOf(':',fieldNameIndex);  // find the size delimiter
        int dataTypeIndex = -1;
        if (fieldLengthIndex >= 0)
        {
          dataTypeIndex = record.indexOf(':',fieldLengthIndex+1);  // check for a second : indicating there is a data type
          if (dataTypeIndex > closingBracketIndex)
            dataTypeIndex = -1; // second : was found but it was beyond the closing >
        }

        if ((closingBracketIndex > fieldNameIndex) && (fieldLengthIndex > fieldNameIndex) && (fieldLengthIndex< closingBracketIndex))
        {
            int fieldLengthCharCount = closingBracketIndex - fieldLengthIndex -1;
            if (dataTypeIndex >= 0)
              fieldLengthCharCount -= 2; // data type indicator is always a colon followed by a single character
            QString fieldLengthString = record.mid(fieldLengthIndex+1,fieldLengthCharCount);
            int fieldLength = fieldLengthString.toInt();
            if (fieldLength > 0)
            {
              QString field = record.mid(closingBracketIndex+1,fieldLength);
              return field;
            }
       }
    }
    return "";
}



void ADIF::load()
{
  _data.clear();
  _data2.clear();
    QFile inputFile(_filename);
    if (inputFile.open(QIODevice::ReadOnly))
    {
      QTextStream in(&inputFile);
      QString buffer;
      bool pre_read {false};
      int end_position {-1};

      // skip optional header record
      do
        {
          buffer += in.readLine () + '\n';
          if (buffer.startsWith (QChar {'<'})) // denotes no header
            {
              pre_read = true;
            }
          else
            {
              end_position = buffer.indexOf ("<EOH>", 0, Qt::CaseInsensitive);
            }
        }
      while (!in.atEnd () && !pre_read && end_position < 0);
      if (!pre_read)            // found header
        {
          buffer.remove (0, end_position + 5);
        }
      while (buffer.size () || !in.atEnd ())
        {
          do
            {
              end_position = buffer.indexOf ("<EOR>", 0, Qt::CaseInsensitive);
              if (!in.atEnd () && end_position < 0)
                {
                  buffer += in.readLine () + '\n';
                }
            }
          while (!in.atEnd () && end_position < 0);
          int record_length {end_position >= 0 ? end_position + 5 : -1};
          auto record = buffer.left (record_length).trimmed ();
          auto next_record = buffer.indexOf (QChar {'<'}, record_length);
          buffer.remove (0, next_record >=0 ? next_record : buffer.size ());
          record = record.mid (record.indexOf (QChar {'<'}));
          add (extractField (record, "CALL")
               , extractField (record, "GRIDSQUARE")
               , extractField (record, "BAND")
               , extractField (record, "MODE")
               , extractField (record, "QSO_DATE"));
        }
        inputFile.close ();
    }
}


void ADIF::add(QString const& call, QString const& grid, QString const& band,
               QString const& mode, QString const& date)
{
  QSO q;
  q.call = call;
  q.grid = grid.left(4);   //We only want to test matches to 4-character grids.
  q.band = band;
  q.mode = mode;
  q.date = date;
  if(q.call.size ()) {
    _data.insert(q.call,q);
    _data2.insert(q.grid,q);
//    qDebug() << "In the log:" << call << grid << band << mode << date;
  }
}

// return true if in the log same band and mode (where JT65 == JT9 == FT8)
bool ADIF::match(QString const& call, QString const& band, QString const& mode) const
{
  QList<QSO> qsos;
  QRegularExpression grid_regexp {"\\A(?![Rr]{2}73)[A-Ra-r]{2}[0-9]{2}([A-Xa-x]{2}){0,1}\\z"};
  if(!call.contains(grid_regexp)) {
    qsos = _data.values(call);
  } else {
    qsos = _data2.values(call);
  }
//  qDebug() << "AA" << call << qsos.size();
  if (qsos.size()>0) {
    QSO q;
    foreach(q,qsos) {
      if((band.compare(q.band,Qt::CaseInsensitive) == 0) || (band=="") || (q.band=="")) {
        if((
             ((mode.compare("JT65",Qt::CaseInsensitive)==0) ||
              (mode.compare("JT9",Qt::CaseInsensitive)==0)  ||
              (mode.compare("FT8",Qt::CaseInsensitive)==0))
             &&
             ((q.mode.compare("JT65",Qt::CaseInsensitive)==0) ||
              (q.mode.compare("JT9",Qt::CaseInsensitive)==0)  ||
              (q.mode.compare("FT8",Qt::CaseInsensitive)==0))
             )
           || (mode.compare(q.mode,Qt::CaseInsensitive)==0)
           || (mode=="")
           || (q.mode=="")
           )
          return true;
      }
    }
  }
  return false;
}    

QList<QString> ADIF::getCallList() const
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


    
int ADIF::getCount() const
{
    return _data.size();
}   
    
QByteArray ADIF::QSOToADIF(QString const& hisCall, QString const& hisGrid, QString const& mode,
      QString const& rptSent, QString const& rptRcvd, QDateTime const& dateTimeOn,
      QDateTime const& dateTimeOff, QString const& band, QString const& comments,
      QString const& name, QString const& strDialFreq, QString const& m_myCall,
      QString const& m_myGrid, QString const& m_txPower, QString const& operator_call,
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
  t += " <station_callsign:" + QString::number(m_myCall.length()) + ">" + m_myCall;
  t += " <my_gridsquare:" + QString::number(m_myGrid.length()) + ">" + m_myGrid;
  if(m_txPower!="") t += " <tx_pwr:" + QString::number(m_txPower.length()) + ">" + m_txPower;
  if(comments!="") t += " <comment:" + QString::number(comments.length()) + ">" + comments;
  if(name!="") t += " <name:" + QString::number(name.length()) + ">" + name;
  if(operator_call!="") t+=" <operator:" + QString::number(operator_call.length()) + ">" + operator_call;
  if(xSent!="") t += " <STX_STRING:" + QString::number(xSent.length()) + ">" + xSent;
  if(xRcvd!="") t += " <SRX_STRING:" + QString::number(xRcvd.length()) + ">" + xRcvd;
  return t.toLatin1();
}

// open ADIF file and append the QSO details. Return true on success
bool ADIF::addQSOToFile(QByteArray const& ADIF_record)
{
    QFile f2(_filename);
    if (!f2.open(QIODevice::Text | QIODevice::Append))
        return false;
    else
    {
        QTextStream out(&f2);
        if (f2.size()==0)
            out << "WSJT-X ADIF Export<eoh>" << endl;  // new file

        out << ADIF_record << " <eor>" << endl;
        f2.close();
    }
    return true;
}
