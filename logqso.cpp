#include "logqso.h"
#include "ui_logqso.h"
#include <QString>
#include <QDebug>


LogQSO::LogQSO(QWidget *parent) :
  QDialog(parent),
  ui(new Ui::LogQSO)
{
  ui->setupUi(this);
}

LogQSO::~LogQSO()
{
  delete ui;
}

void LogQSO::initLogQSO(QString hisCall, QString hisGrid, QString mode,
                        QString rptSent, QString rptRcvd, QDateTime dateTime,
                        double dialFreq, QString myCall, QString myGrid,
                        bool noSuffix, bool toRTTY, bool dBtoComments)
{
  ui->call->setText(hisCall);
  ui->grid->setText(hisGrid);
  ui->txPower->setText("");
  ui->comments->setText("");
  if(m_saveTxPower) ui->txPower->setText(m_txPower);
  if(m_saveComments) ui->comments->setText(m_comments);
  if(dBtoComments) {
    QString t=mode;
    if(rptSent!="") t+="  Sent: " + rptSent;
    if(rptRcvd!="") t+="  Rcvd: " + rptRcvd;
    ui->comments->setText(t);
  }
  if(noSuffix and mode.mid(0,3)=="JT9") mode="JT9";
  if(toRTTY and mode.mid(0,3)=="JT9") mode="RTTY";
  ui->mode->setText(mode);
  ui->sent->setText(rptSent);
  ui->rcvd->setText(rptRcvd);
  m_dateTime=dateTime;
  QString date=dateTime.toString("yyyy-MM-dd");
  ui->date->setText(date);
  QString time=dateTime.toString("hhmm");
  ui->time->setText(time);
  m_dialFreq=dialFreq;
  m_myCall=myCall;
  m_myGrid=myGrid;
  QString band="";
  if(dialFreq>0.135 and dialFreq<0.139) band="2200m";
  if(dialFreq>0.45 and dialFreq<0.55) band="630m";
  if(dialFreq>1.8 and dialFreq<2.0) band="160m";
  if(dialFreq>3.5 and dialFreq<4.0) band="80m";
  if(dialFreq>5.1 and dialFreq<5.45) band="60m";
  if(dialFreq>7.0 and dialFreq<7.3) band="40m";
  if(dialFreq>10.0 and dialFreq<10.15) band="30m";
  if(dialFreq>14.0 and dialFreq<14.35) band="20m";
  if(dialFreq>18.068 and dialFreq<18.168) band="17m";
  if(dialFreq>21.0 and dialFreq<21.45) band="15m";
  if(dialFreq>24.890 and dialFreq<24.990) band="12m";
  if(dialFreq>28.0 and dialFreq<29.7) band="10m";
  if(dialFreq>50.0 and dialFreq<54.0) band="6m";
  if(dialFreq>70.0 and dialFreq<71.0) band="4m";
  if(dialFreq>144.0 and dialFreq<148.0) band="2m";
  if(dialFreq>222.0 and dialFreq<225.0) band="1.25m";
  if(dialFreq>420.0 and dialFreq<450.0) band="70cm";
  if(dialFreq>902.0 and dialFreq<928.0) band="33cm";
  if(dialFreq>1240.0 and dialFreq<1300.0) band="23cm";
  if(dialFreq>2300.0 and dialFreq<2450.0) band="13cm";
  if(dialFreq>3300.0 and dialFreq<3500.0) band="9cm";
  if(dialFreq>5650.0 and dialFreq<5925.0) band="6cm";
  if(dialFreq>10000.0 and dialFreq<10500.0) band="3cm";
  if(dialFreq>24000.0 and dialFreq<24250.0) band="1.25cm";
  if(dialFreq>47000.0 and dialFreq<47200.0) band="6mm";
  if(dialFreq>75500.0 and dialFreq<81000.0) band="4mm";
  ui->band->setText(band);
  ui->cbTxPower->setChecked(m_saveTxPower);
  ui->cbComments->setChecked(m_saveComments);
}

void LogQSO::accept()
{
  QString hisCall,hisGrid,mode,rptSent,rptRcvd,date,time,band;
  QString comments,name;

  hisCall=ui->call->text();
  hisGrid=ui->grid->text();
  mode=ui->mode->text();
  rptSent=ui->sent->text();
  rptRcvd=ui->rcvd->text();
  date=ui->date->text();
  date=date.mid(0,4) + date.mid(5,2) + date.mid(8,2);
  time=ui->time->text();
  band=ui->band->text();
  name=ui->name->text();
  m_txPower=ui->txPower->text();
  comments=ui->comments->text();
  m_comments=comments;
  QString strDialFreq(QString::number(m_dialFreq,'f',6));

//Log this QSO to file "wsjtx_log.adi"
  QFile f2("wsjtx_log.adi");
  if(!f2.open(QIODevice::Text | QIODevice::Append)) {
    QMessageBox m;
    m.setText("Cannot open file \"wsjtx_log.adi\".");
    m.exec();
  } else {
    QTextStream out(&f2);
    if(f2.size()==0) out << "WSJT-X ADIF Export<eoh>" << endl;

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

//Log this QSO to file "wsjtx.log"
  QFile f("wsjtx.log");
  if(!f.open(QIODevice::Text | QIODevice::Append)) {
    QMessageBox m;
    m.setText("Cannot open file \"wsjtx.log\".");
    m.exec();
  } else {
    QString logEntry=m_dateTime.date().toString("yyyy-MMM-dd,") +
           m_dateTime.time().toString("hh:mm,") + hisCall + "," +
           hisGrid + "," + strDialFreq + "," + mode +
               "," + rptSent + "," + rptRcvd;
       if(m_txPower!="") logEntry += "," + m_txPower;
       if(comments!="") logEntry += "," + comments;
       if(name!="") logEntry += "," + name;
    QTextStream out(&f);
    out << logEntry << endl;
    f.close();
  }

//Clean up and finish logging
  emit(acceptQSO(true));
  QDialog::accept();
}

void LogQSO::reject()
{
  emit(acceptQSO(false));
  QDialog::reject();
}

void LogQSO::on_cbTxPower_toggled(bool checked)
{
  m_saveTxPower=checked;
}

void LogQSO::on_cbComments_toggled(bool checked)
{
  m_saveComments=checked;
}
