#include <QStringList>
#include <QDebug>
#include "decodedtext.h"



QString DecodedText::CQersCall()
{
    // extract the CQer's call   TODO: does this work with all call formats?  What about 'CQ DX'?
    int s1 = 4 + _string.indexOf(" CQ ");
    int s2 = _string.indexOf(" ",s1);
    QString call = _string.mid(s1,s2-s1);
    return call;
}


bool DecodedText::isJT65()
{
    return _string.indexOf("#") == column_mode;
}

bool DecodedText::isJT9()
{
    return _string.indexOf("@") == column_mode;
}

bool DecodedText::isTX()
{
    int i = _string.indexOf("Tx");
    return (i >= 0 && i < 15); // TODO guessing those numbers. Does Tx ever move?
}

int DecodedText::frequencyOffset()
{
    return _string.mid(column_freq,4).toInt();
}

int DecodedText::snr()
{
    return _string.mid(column_snr,3).toInt();
}

/*
2343 -11  0.8 1259 # YV6BFE F6GUU R-08
2343 -19  0.3  718 # VE6WQ SQ2NIJ -14
2343  -7  0.3  815 # KK4DSD W7VP -16
2343 -13  0.1 3627 @ CT1FBK IK5YZT R+02

0605  Tx      1259 # CQ VK3ACF QF22
*/

// find and extract any report. Returns true if this is a standard message
bool DecodedText::report(const QString myCall, /*mod*/QString& report)
{
    QString msg=_string.mid(column_qsoText);
    int i1=msg.indexOf("\r");
    if (i1>0)
        msg=msg.mid(0,i1-1) + "                      ";
    bool b = stdmsg_(msg.mid(0,22).toLatin1().constData(),22);  // stdmsg is a fortran routine that packs the text, unpacks it and compares the result

    QStringList w=msg.split(" ",QString::SkipEmptyParts);
    if(b and w[0]==myCall)
    {
        QString tt="";
        if(w.length()>=3) tt=w[2];
        bool ok;
        i1=tt.toInt(&ok);
        if (ok and i1>=-50 and i1<50)
        {
            report = tt;
//            qDebug() << "report for " << _string << "::" << report;
        }
        else
        {
            if (tt.mid(0,1)=="R")
            {
                i1=tt.mid(1).toInt(&ok);
                if(ok and i1>=-50 and i1<50)
                {
                    report = tt.mid(1);
//                    qDebug() << "report for " << _string << "::" << report;
                }
            }
        }
    }
    return b;
}

// get the first text word, usually the call
QString DecodedText::call()
{
    QString call = _string.mid(column_qsoText);
    int i = call.indexOf(" ");
    call = call.mid(0,i);
    return call;
}

// get the second word, most likely the de call and the third word, most likely grid
void DecodedText::deCallAndGrid(/*out*/QString& call, QString& grid)
{
    QString msg=_string.mid(column_qsoText);
    int i1 = msg.indexOf(" ");
    call = msg.mid(i1+1);
    int i2 = call.indexOf(" ");
    grid = call.mid(i2+1,4);
    call = call.mid(0,i2);
}

int DecodedText::timeInSeconds()
{
    return 60*_string.mid(column_time,2).toInt() + _string.mid(2,2).toInt();
}

/*
2343 -11  0.8 1259 # YV6BFE F6GUU R-08
2343 -19  0.3  718 # VE6WQ SQ2NIJ -14
2343  -7  0.3  815 # KK4DSD W7VP -16
2343 -13  0.1 3627 @ CT1FBK IK5YZT R+02

0605  Tx      1259 # CQ VK3ACF QF22
*/

QString DecodedText::report()  // returns a string of the SNR field with a leading + or - followed by two digits
{
    int sr = snr();
    if (sr<-50)
        sr = -50;
    else
        if (sr > 49)
            sr = 49;

    QString rpt;
    rpt.sprintf("%d",abs(sr));
    if (sr > 9)
        rpt = "+" + rpt;
    else
        if (sr >= 0)
            rpt = "+0" + rpt;
        else
            if (sr >= -9)
                rpt = "-0" + rpt;
            else
                rpt = "-" + rpt;
    return rpt;
}
