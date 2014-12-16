#include "adif.h"

#include <QFile>
#include <QTextStream>
#include <QDebug>

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


void ADIF::add(const QString call, const QString band, const QString mode, const QString date)
{
    QSO q;
    q.call = call;
    q.band = band;
    q.mode = mode;
    q.date = date;
    _data.insert(q.call,q);
    //qDebug() << "Added as worked:" << call << band << mode << date;
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
            if (     (band.compare(q.band,Qt::CaseInsensitive) == 0)
                  || (band=="")
                  || (q.band==""))
            {
                if (
                     (
                       ((mode.compare("JT65",Qt::CaseInsensitive)==0) || (mode.compare("JT9",Qt::CaseInsensitive)==0))
                       &&
                       ((q.mode.compare("JT65",Qt::CaseInsensitive)==0) || (q.mode.compare("JT9",Qt::CaseInsensitive)==0))
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
    

// open ADIF file and append the QSO details. Return true on success
bool ADIF::addQSOToFile(const QString hisCall, const QString hisGrid, const QString mode, const QString rptSent, const QString rptRcvd, const QString date, const QString time, const QString band,
                        const QString comments, const QString name, const QString strDialFreq, const QString m_myCall, const QString m_myGrid, const QString m_txPower)
{
    QFile f2(_filename);
    if (!f2.open(QIODevice::Text | QIODevice::Append))
        return false;
    else
    {
        QTextStream out(&f2);
        if (f2.size()==0)
            out << "WSJT-X ADIF Export<eoh>" << endl;  // new file

        QString t;
        t="<call:" + QString::number(hisCall.length()) + ">" + hisCall;
        t+=" <gridsquare:" + QString::number(hisGrid.length()) + ">" + hisGrid;
        t+=" <mode:" + QString::number(mode.length()) + ">" + mode;
        t+=" <rst_sent:" + QString::number(rptSent.length()) + ">" + rptSent;
        t+=" <rst_rcvd:" + QString::number(rptRcvd.length()) + ">" + rptRcvd;
        t+=" <qso_date:8>" + date;
        t+=" <time_on:4>" + time;
        t+=" <band:" + QString::number(band.length()) + ">" + band;
        t+=" <freq:" + QString::number(strDialFreq.length()) + ">" + strDialFreq;
        t+=" <station_callsign:" + QString::number(m_myCall.length()) + ">" +
                m_myCall;
        t+=" <my_gridsquare:" + QString::number(m_myGrid.length()) + ">" +
                m_myGrid;
        if(m_txPower!="") t+= " <tx_pwr:" + QString::number(m_txPower.length()) +
                ">" + m_txPower;
        if(comments!="") t+=" <comment:" + QString::number(comments.length()) +
                ">" + comments;
        if(name!="") t+=" <name:" + QString::number(name.length()) +
                ">" + name;
        t+=" <eor>";
        out << t << endl;
        f2.close();
    }
    return true;
}

QString ADIF::bandFromFrequency(double dialFreq)
{
    QString band="";
    if(dialFreq>0.135 and dialFreq<0.139) band="2200m";
    else if(dialFreq>0.45 and dialFreq<0.55) band="630m";
    else if(dialFreq>1.8 and dialFreq<2.0) band="160m";
    else if(dialFreq>3.5 and dialFreq<4.0) band="80m";
    else if(dialFreq>5.1 and dialFreq<5.45) band="60m";
    else if(dialFreq>7.0 and dialFreq<7.3) band="40m";
    else if(dialFreq>10.0 and dialFreq<10.15) band="30m";
    else if(dialFreq>14.0 and dialFreq<14.35) band="20m";
    else if(dialFreq>18.068 and dialFreq<18.168) band="17m";
    else if(dialFreq>21.0 and dialFreq<21.45) band="15m";
    else if(dialFreq>24.890 and dialFreq<24.990) band="12m";
    else if(dialFreq>28.0 and dialFreq<29.7) band="10m";
    else if(dialFreq>50.0 and dialFreq<54.0) band="6m";
    else if(dialFreq>70.0 and dialFreq<71.0) band="4m";
    else if(dialFreq>144.0 and dialFreq<148.0) band="2m";
    else if(dialFreq>222.0 and dialFreq<225.0) band="1.25m";
    else if(dialFreq>420.0 and dialFreq<450.0) band="70cm";
    else if(dialFreq>902.0 and dialFreq<928.0) band="33cm";
    else if(dialFreq>1240.0 and dialFreq<1300.0) band="23cm";
    else if(dialFreq>2300.0 and dialFreq<2450.0) band="13cm";
    else if(dialFreq>3300.0 and dialFreq<3500.0) band="9cm";
    else if(dialFreq>5650.0 and dialFreq<5925.0) band="6cm";
    else if(dialFreq>10000.0 and dialFreq<10500.0) band="3cm";
    else if(dialFreq>24000.0 and dialFreq<24250.0) band="1.25cm";
    else if(dialFreq>47000.0 and dialFreq<47200.0) band="6mm";
    else if(dialFreq>75500.0 and dialFreq<81000.0) band="4mm";
    return band;
}
