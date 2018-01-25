#include "logqso.h"

#include <QString>
#include <QSettings>
#include <QStandardPaths>
#include <QDir>
#include <QDebug>
#include <QUdpSocket>

#include "logbook/adif.h"
#include "MessageBox.hpp"
#include "Configuration.hpp"
#include "Bands.hpp"

#include "ui_logqso.h"
#include "moc_logqso.cpp"

LogQSO::LogQSO(QString const& programTitle, QSettings * settings
               , Configuration const * config, QWidget *parent)
  : QDialog(parent)
  , ui(new Ui::LogQSO)
  , m_settings (settings)
  , m_config {config}
{
  ui->setupUi(this);
  setWindowTitle(programTitle + " - Log QSO");
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

void LogQSO::initLogQSO(QString const& hisCall, QString const& hisGrid, QString mode,
                        QString const& rptSent, QString const& rptRcvd,
                        QDateTime const& dateTimeOn, QDateTime const& dateTimeOff,
                        Radio::Frequency dialFreq, QString const& myCall, QString const& myGrid,
                        bool noSuffix, bool toRTTY, bool dBtoComments, bool bFox, QString const& opCall)
{
  if(!isHidden()) return;
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
  ui->start_date_time->setDateTime (dateTimeOn);
  ui->end_date_time->setDateTime (dateTimeOff);
  m_dialFreq=dialFreq;
  m_myCall=myCall;
  m_myGrid=myGrid;
  ui->band->setText (m_config->bands ()->find (dialFreq));
  ui->loggedOperator->setText(opCall);
  if(bFox) {
    accept();
  } else {
    show ();
  }
}

void LogQSO::accept()
{
  QString hisCall,hisGrid,mode,rptSent,rptRcvd,dateOn,dateOff,timeOn,timeOff,band,operator_call;
  QString comments,name;

  hisCall=ui->call->text();
  hisGrid=ui->grid->text();
  mode=ui->mode->text();
  rptSent=ui->sent->text();
  rptRcvd=ui->rcvd->text();
  m_dateTimeOn = ui->start_date_time->dateTime ();
  m_dateTimeOff = ui->end_date_time->dateTime ();
  band=ui->band->text();
  name=ui->name->text();
  m_txPower=ui->txPower->text();
  comments=ui->comments->text();
  m_comments=comments;
  QString strDialFreq(QString::number(m_dialFreq / 1.e6,'f',6));
  operator_call = ui->loggedOperator->text();
  //Log this QSO to ADIF file "wsjtx_log.adi"
  QString filename = "wsjtx_log.adi";  // TODO allow user to set
  ADIF adifile;
  auto adifilePath = QDir {QStandardPaths::writableLocation (QStandardPaths::DataLocation)}.absoluteFilePath ("wsjtx_log.adi");
  adifile.init(adifilePath);

  if (!adifile.addQSOToFile(hisCall,hisGrid,mode,rptSent,rptRcvd,m_dateTimeOn,m_dateTimeOff,band,comments,name,strDialFreq,m_myCall,m_myGrid,m_txPower, operator_call))
  {
    MessageBox::warning_message (this, tr ("Log file error"),
                                 tr ("Cannot open \"%1\"").arg (adifilePath));
  }

  // Log to N1MM Logger
  if (m_config->broadcast_to_n1mm() && m_config->valid_n1mm_info())  {
    QString adif = adifile.QSOToADIF(hisCall,hisGrid,mode,rptSent,rptRcvd,m_dateTimeOn,m_dateTimeOff,band,comments,name,strDialFreq,m_myCall,m_myGrid,m_txPower, operator_call);
    const QHostAddress n1mmhost = QHostAddress(m_config->n1mm_server_name());
    QByteArray qba_adif = adif.toLatin1();
    QUdpSocket _sock;

    auto rzult = _sock.writeDatagram ( qba_adif, n1mmhost, quint16(m_config->n1mm_server_port()));
    if (rzult == -1) {
      MessageBox::warning_message (this, tr ("Error sending log to N1MM"),
                                   tr ("Write returned \"%1\"").arg (rzult));
    }
  }

//Log this QSO to file "wsjtx.log"
  static QFile f {QDir {QStandardPaths::writableLocation (QStandardPaths::DataLocation)}.absoluteFilePath ("wsjtx.log")};
  if(!f.open(QIODevice::Text | QIODevice::Append)) {
    MessageBox::warning_message (this, tr ("Log file error"),
                                 tr ("Cannot open \"%1\" for append").arg (f.fileName ()),
                                 tr ("Error: %1").arg (f.errorString ()));
  } else {
    QString logEntry=m_dateTimeOn.date().toString("yyyy-MM-dd,") +
      m_dateTimeOn.time().toString("hh:mm:ss,") +
      m_dateTimeOff.date().toString("yyyy-MM-dd,") +
      m_dateTimeOff.time().toString("hh:mm:ss,") + hisCall + "," +
      hisGrid + "," + strDialFreq + "," + mode +
      "," + rptSent + "," + rptRcvd + "," + m_txPower +
      "," + comments + "," + name;
    QTextStream out(&f);
    out << logEntry << endl;
    f.close();
  }

//Clean up and finish logging
  Q_EMIT acceptQSO (m_dateTimeOff, hisCall, hisGrid, m_dialFreq, mode, rptSent, rptRcvd, m_txPower, comments, name,m_dateTimeOn, operator_call);
  QDialog::accept();
}

// closeEvent is only called from the system menu close widget for a
// modeless dialog so we use the hideEvent override to store the
// window settings
void LogQSO::hideEvent (QHideEvent * e)
{
  storeSettings ();
  QDialog::hideEvent (e);
}
