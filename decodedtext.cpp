#include "decodedtext.h"

#include <QStringList>
#include <QRegularExpression>

extern "C" {
  bool stdmsg_(const char* msg, int len);
}

DecodedText::DecodedText (QString const& the_string)
  : string_ {the_string}
  , padding_ {the_string.indexOf (" ") > 4 ? 2 : 0} // allow for
                                                    // seconds
  , message_ {string_.mid (column_qsoText + padding_).trimmed ()}
  , is_standard_ {false}
{
  if (message_.length() >= 1)
    {
      message_ = message_.left (22).remove (QRegularExpression {"[<>]"});
      int i1 = message_.indexOf ('\r');
      if (i1 > 0)
        {
          message_ = message_.left (i1 - 1);
        }
      // stdmsg is a fortran routine that packs the text, unpacks it and compares the result
      is_standard_ = stdmsg_ ((message_ + "                      ").toLatin1 ().constData (),22);
    }
};

void DecodedText::removeAddedInfo ()
{
  if (string_.indexOf (" CQ ") > 0) {
    // TODO this magic 37 characters is also referenced in DisplayText::_appendDXCCWorkedB4()
    auto eom_pos = string_.indexOf (' ', 37);
    if (eom_pos < 37) eom_pos = string_.size () - 1; // we always want at least the characters
                            // to position 37
    string_ = string_.left (eom_pos + 1);  // remove DXCC entity and worked B4 status. TODO need a better way to do this
  }
}

QString DecodedText::CQersCall() const
{
  QRegularExpression callsign_re {R"(^(CQ|DE|QRZ)(\s?DX|\s([A-Z]{2}|\d{3}))?\s(?<callsign>[A-Z0-9/]{2,})(\s[A-R]{2}[0-9]{2})?)"};
  return callsign_re.match (message_).captured ("callsign");
}


bool DecodedText::isJT65() const
{
    return string_.indexOf("#") == column_mode + padding_;
}

bool DecodedText::isJT9() const
{
    return string_.indexOf("@") == column_mode + padding_;
}

bool DecodedText::isTX() const
{
    int i = string_.indexOf("Tx");
    return (i >= 0 && i < 15); // TODO guessing those numbers. Does Tx ever move?
}

bool DecodedText::isLowConfidence () const
{
  return QChar {'?'} == string_.mid (padding_ + column_qsoText + 21, 1);
}

int DecodedText::frequencyOffset() const
{
    return string_.mid(column_freq + padding_,4).toInt();
}

int DecodedText::snr() const
{
  int i1=string_.indexOf(" ")+1;
  return string_.mid(i1,3).toInt();
}

float DecodedText::dt() const
{
  return string_.mid(column_dt + padding_,5).toFloat();
}

/*
2343 -11  0.8 1259 # YV6BFE F6GUU R-08
2343 -19  0.3  718 # VE6WQ SQ2NIJ -14
2343  -7  0.3  815 # KK4DSD W7VP -16
2343 -13  0.1 3627 @ CT1FBK IK5YZT R+02

0605  Tx      1259 # CQ VK3ACF QF22
*/

// find and extract any report. Returns true if this is a standard message
bool DecodedText::report(QString const& myBaseCall, QString const& dxBaseCall, /*mod*/QString& report) const
{
  if (message_.size () < 1) return false;

  QStringList const& w = message_.split(" ",QString::SkipEmptyParts);
  if (w.size ()
      && is_standard_ && (w[0] == myBaseCall
                          || w[0].endsWith ("/" + myBaseCall)
                          || w[0].startsWith (myBaseCall + "/")
                          || (w.size () > 1 && !dxBaseCall.isEmpty ()
                              && (w[1] == dxBaseCall
                                  || w[1].endsWith ("/" + dxBaseCall)
                                  || w[1].startsWith (dxBaseCall + "/")))))
    {
      QString tt="";
      if(w.size() > 2) tt=w[2];
      bool ok;
      auto i1=tt.toInt(&ok);
      if (ok and i1>=-50 and i1<50)
        {
          report = tt;
        }
      else
        {
          if (tt.mid(0,1)=="R")
            {
              i1=tt.mid(1).toInt(&ok);
              if(ok and i1>=-50 and i1<50)
                {
                  report = tt.mid(1);
                }
            }
        }
    }
  return is_standard_;
}

// get the first text word, usually the call
QString DecodedText::call() const
{
  auto call = string_;
  call = call.replace (QRegularExpression {" CQ ([A-Z]{2,2}|[0-9]{3,3}) "}, " CQ_\\1 ").mid (column_qsoText + padding_);
  int i = call.indexOf(" ");
  return call.mid(0,i);
}

// get the second word, most likely the de call and the third word, most likely grid
void DecodedText::deCallAndGrid(/*out*/QString& call, QString& grid) const
{
  auto msg = string_;
  if(msg.mid(4,1)!=" ") msg=msg.mid(0,4)+msg.mid(6,-1);  //Remove seconds from UTC
  msg = msg.replace (QRegularExpression {" CQ ([A-Z]{2,2}|[0-9]{3,3}) "}, " CQ_\\1 ").mid (column_qsoText + padding_);
  int i1 = msg.indexOf (" ");
  call = msg.mid (i1 + 1);
  int i2 = call.indexOf (" ");
  if (" R " == call.mid (i2, 3)) // MSK144 contest mode report
    {
      grid = call.mid (i2 + 3, 4);
    }
  else
    {
      grid = call.mid (i2 + 1, 4);
    }
  call = call.left (i2).replace (">", "");
}

int DecodedText::timeInSeconds() const
{
    return 60*string_.mid(column_time,2).toInt() + string_.mid(2,2).toInt();
}

/*
2343 -11  0.8 1259 # YV6BFE F6GUU R-08
2343 -19  0.3  718 # VE6WQ SQ2NIJ -14
2343  -7  0.3  815 # KK4DSD W7VP -16
2343 -13  0.1 3627 @ CT1FBK IK5YZT R+02

0605  Tx      1259 # CQ VK3ACF QF22
*/

QString DecodedText::report() const // returns a string of the SNR field with a leading + or - followed by two digits
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
