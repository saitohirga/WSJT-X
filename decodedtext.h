// -*- Mode: C++ -*-
/*
 * Class to handle the formatted string as returned from the fortran decoder
 *
 * VK3ACF August 2013
 */


#ifndef DECODEDTEXT_H
#define DECODEDTEXT_H

#include <QString>



/*
0123456789012345678901234567890123456789
^    ^    ^   ^    ^ ^
2343 -11  0.8 1259 # YV6BFE F6GUU R-08
2343 -19  0.3  718 # VE6WQ SQ2NIJ -14
2343  -7  0.3  815 # KK4DSD W7VP -16
2343 -13  0.1 3627 @ CT1FBK IK5YZT R+02

0605  Tx      1259 # CQ VK3ACF QF22
*/

class DecodedText
{
public:
     // These define the columns in the decoded text where fields are to be found.
     // We rely on these columns being the same in the fortran code (lib/decode.f90) that formats the decoded text
     enum Columns { column_time    = 0,
                    column_snr     = 5,
                    column_freq    = 14,
                    column_mode    = 19,
                    column_qsoText = 21 };

    void operator=(const QString &rhs)
    {
        _string = rhs;
    };
    void operator=(const QByteArray &rhs)
    {
        _string = rhs;
    };

    void operator+=(const QString &rhs)
    {
        _string += rhs;
    };

    QString string() { return _string; };

    int indexOf(QString s) { return _string.indexOf(s); };
    int indexOf(QString s, int i) { return _string.indexOf(s,i); };
    QString mid(int f, int t) { return _string.mid(f,t); };
    QString left(int i) { return _string.left(i); };

    void clear() { _string.clear(); };

    QString CQersCall();

    bool isJT65();
    bool isJT9();
    bool isTX();
    int frequencyOffset();  // hertz offset from the tuned dial or rx frequency, aka audio frequency
    int snr();

    // find and extract any report. Returns true if this is a standard message
  bool report(QString const& myBaseCall, QString const& dxBaseCall, /*mod*/QString& report);

    // get the first text word, usually the call
    QString call();

    // get the second word, most likely the de call and the third word, most likely grid
    void deCallAndGrid(/*out*/QString& call, QString& grid);

    int timeInSeconds();

    // returns a string of the SNR field with a leading + or - followed by two digits
    QString report();

private:
    QString _string;
    
};


extern "C" {  bool stdmsg_(const char* msg, int len); }

#endif // DECODEDTEXT_H
