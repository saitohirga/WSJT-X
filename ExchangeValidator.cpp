#include <QDebug>
#include "ExchangeValidator.hpp"

ExchangeValidator::ExchangeValidator (QObject * parent)
  : QValidator {parent}
{
}

auto ExchangeValidator::validate (QString& input, int& length) const -> State
{
  bool ok=false;
  QStringList w=input.split(" ");
  int nwords=w.size();
  length=input.size();
  input = input.toUpper ();

  if(nwords==1 and length<=3) {
    //ARRL RTTY Roundup
//    ntype=4;
//    ok=exch_valid_(&ntype, const_cast<char *>(input.toLatin1().constData()),length);
    QStringList states;
    states << "AL" << "AK" << "AZ" << "AR" << "CA" << "CO"
           << "CT" << "DE" << "FL" << "GA" << "HI" << "ID"
           << "IL" << "IN" << "IA" << "KS" << "KY" << "LA"
           << "ME" << "MD" << "MA" << "MI" << "MN" << "MS"
           << "MO" << "MT" << "NE" << "NV" << "NH" << "NJ"
           << "NM" << "NY" << "NC" << "ND" << "OH" << "OK"
           << "OR" << "PA" << "RI" << "SC" << "SD" << "TN"
           << "TX" << "UT" << "VT" << "VA" << "WA" << "WV"
           << "WI" << "WY" << "NB" << "NS" << "QC" << "ON"
           << "MB" << "SK" << "AB" << "BC" << "NWT" << "NF"
           << "LB" << "NU" << "YT" << "PEI" << "DC" << "DX";
    if(states.contains(input)) ok=true;

  }
  if(nwords==2 and w.at(1).size()<=3) {
    //ARRL Field Day
    int n=w.at(0).size();
    if(n>3) goto done;
    int ntx=w.at(0).left(n-1).toInt();
    if(ntx<1 or ntx>32) goto done;
    QString c1=w.at(0).right(1);
    if(c1<"A" or c1>"F") goto done;
    QStringList sections;
    sections << "AB" << "AK" << "AL" << "AR" << "AZ" << "BC"
             << "CO" << "CT" << "DE" << "EB" << "EMA" << "ENY"
             << "EPA" << "EWA" << "GA" << "GTA" << "IA" << "ID"
             << "IL" << "IN" << "KS" << "KY" << "LA" << "LAX"
             << "MAR" << "MB" << "MDC" << "ME" << "MI" << "MN"
             << "MO" << "MS" << "MT" << "NC" << "ND" << "NE"
             << "NFL" << "NH" << "NL" << "NLI" << "NM" << "NNJ"
             << "NNY" << "NT" << "NTX" << "NV" << "OH" << "OK"
             << "ONE" << "ONN" << "ONS" << "OR" << "ORG" << "PAC"
             << "PR" << "QC" << "RI" << "SB" << "SC" << "SCV"
             << "SD" << "SDG" << "SF" << "SFL" << "SJV" << "SK"
             << "SNJ" << "STX" << "SV" << "TN" << "UT" << "VA"
             << "VI" << "VT" << "WCF" << "WI" << "WMA" << "WNY"
             << "WPA" << "WTX" << "WV" << "WWA" << "WY" << "DX";
    if(sections.contains(w.at(1))) ok=true;
  }

done:
  if(ok) return Acceptable;
  return Intermediate;
}
