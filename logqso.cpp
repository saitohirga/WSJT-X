#include "logqso.h"

#include <QString>
#include <QSettings>
#include <QDir>
#include <QDebug>

#include "Configuration.hpp"
#include "logbook/adif.h"

#include "ui_logqso.h"

#include "moc_logqso.cpp"

LogQSO::LogQSO(QSettings * settings, Configuration const * configuration, QWidget *parent) :
  QDialog(parent),
  ui(new Ui::LogQSO),
  m_settings (settings),
  m_configuration (configuration)
{
  ui->setupUi(this);

  loadSettings ();
}

LogQSO::~LogQSO ()
{
}

void LogQSO::loadSettings ()
{
  m_settings->beginGroup ("LogQSO");
  restoreGeometry (m_settings->value ("geometry", saveGeometry ()).toByteArray ());
  ui->cbTxPower->setChecked (m_settings->value ("SaveTxPower", false).toBool ());
  ui->cbComments->setChecked (m_settings->value ("SaveComments", false).toBool ());
  m_txPower = m_settings->value ("TxPower", "").toString ();
  m_comments = m_settings->value ("LogComments", "").toString();
  m_settings->endGroup ();
}

void LogQSO::storeSettings () const
{
  m_settings->beginGroup ("LogQSO");
  m_settings->setValue ("geometry", saveGeometry ());
  m_settings->setValue ("SaveTxPower", ui->cbTxPower->isChecked ());
  m_settings->setValue ("SaveComments", ui->cbComments->isChecked ());
  m_settings->setValue ("TxPower", m_txPower);
  m_settings->setValue ("LogComments", m_comments);
  m_settings->endGroup ();
}

void LogQSO::initLogQSO(QString hisCall, QString hisGrid, QString mode,
                        QString rptSent, QString rptRcvd, QDateTime dateTime,
                        double dialFreq, QString myCall, QString myGrid,
                        bool noSuffix, bool toRTTY, bool dBtoComments)
{
  ui->call->setText(hisCall);
  ui->grid->setText(hisGrid);
  ui->name->setText("");
  ui->txPower->setText("");
  ui->comments->setText("");
  if (ui->cbTxPower->isChecked ()) ui->txPower->setText(m_txPower);
  if (ui->cbComments->isChecked ()) ui->comments->setText(m_comments);
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
  QString band= ADIF::bandFromFrequency(dialFreq);
  ui->band->setText(band);

  show ();
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

  //Log this QSO to ADIF file "wsjtx_log.adi"
  QString filename = "wsjtx_log.adi";  // TODO allow user to set
  ADIF adifile;
  auto adifilePath = m_configuration->data_path ().absoluteFilePath (filename);
  adifile.init(adifilePath);
  if (!adifile.addQSOToFile(hisCall,hisGrid,mode,rptSent,rptRcvd,date,time,band,comments,name,strDialFreq,m_myCall,m_myGrid,m_txPower))
  {
      QMessageBox m;
      m.setText("Cannot open file \"" + adifilePath + "\".");
      m.exec();
  }

//Log this QSO to file "wsjtx.log"
  QFile f(m_configuration->data_path ().absoluteFilePath ("wsjtx.log"));
  if(!f.open(QIODevice::Text | QIODevice::Append)) {
    QMessageBox m;
    m.setText("Cannot open file \"" + f.fileName () + "\".");
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

// closeEvent is only called from the system menu close widget for a
// modeless dialog so we use the hideEvent override to store the
// window settings
void LogQSO::hideEvent (QHideEvent * e)
{
  storeSettings ();
  QDialog::hideEvent (e);
}
