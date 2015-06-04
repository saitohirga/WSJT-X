#include "astro.h"

#include <stdio.h>

#include <QApplication>
#include <QFile>
#include <QTextStream>
#include <QMessageBox>
#include <QSettings>
#include <QDateTime>
#include <QStandardPaths>
#include <QDir>
#include <QDebug>

#include "commons.h"
#include "qt_helpers.hpp"

#include "ui_astro.h"

#include "moc_astro.cpp"

Astro::Astro(QSettings * settings, QWidget * parent)
  : QWidget {parent}
  , settings_ {settings}
  , ui_ {new Ui::Astro}
{
  ui_->setupUi(this);
  setWindowFlags (Qt::Dialog | Qt::WindowCloseButtonHint | Qt::WindowMinimizeButtonHint);
  setWindowTitle(QApplication::applicationName () + " - " + tr ("Astronomical Data"));
  setStyleSheet ("QWidget {background: white;}");
  read_settings ();
  m_Hz=0;
  ui_->text_label->clear();
}

Astro::~Astro ()
{
  if (isVisible ()) write_settings ();
}

void Astro::closeEvent (QCloseEvent * e)
{
  write_settings ();
  QWidget::closeEvent (e);
}

void Astro::read_settings ()
{
  settings_->beginGroup ("Astro");
  restoreGeometry (settings_->value ("geometry", saveGeometry ()).toByteArray ());
  m_bDopplerTracking=settings_->value("DopplerTracking",false).toBool();
  ui_->cbDopplerTracking->setChecked(m_bDopplerTracking);
  m_DopplerMethod=settings_->value("DopplerMethod",0).toInt();
  if(m_DopplerMethod==0) ui_->rbNoDoppler->setChecked(true);
  if(m_DopplerMethod==1) ui_->rbFullTrack->setChecked(true);
  if(m_DopplerMethod==2) ui_->rbConstFreqOnMoon->setChecked(true);
  m_stepHz=settings_->value("StepHz",1).toInt();
  if(m_stepHz==1) ui_->rb1Hz->setChecked(true);
  if(m_stepHz==10) ui_->rb10Hz->setChecked(true);
  if(m_stepHz==100) ui_->rb100Hz->setChecked(true);
  m_kHz=settings_->value("kHzAdd",100).toInt();
  ui_->kHzSpinBox->setValue(m_kHz);
  m_bRxAudioTrack=settings_->value("RxAudioTrack",false).toBool();
  m_bTxAudioTrack=settings_->value("TxAudioTrack",false).toBool();
  ui_->cbTxAudioTrack->setChecked(m_bTxAudioTrack);
  move (settings_->value ("window/pos", pos ()).toPoint ());
  settings_->endGroup ();
}

void Astro::write_settings ()
{
  settings_->beginGroup ("Astro");
  settings_->setValue ("geometry", saveGeometry ());
  settings_->setValue ("DopplerTracking",m_bDopplerTracking);
  settings_->setValue ("DopplerMethod",m_DopplerMethod);
  settings_->setValue ("StepHz",m_stepHz);
  settings_->setValue ("kHzAdd",m_kHz);
  settings_->setValue ("RxAudioTrack",m_bRxAudioTrack);
  settings_->setValue ("TxAudioTrack",m_bTxAudioTrack);
  settings_->setValue ("window/pos", pos ());
  settings_->endGroup ();
}

void Astro::astroUpdate(QDateTime t, QString mygrid, QString hisgrid, qint64 freqMoon,
                        qint32* ndop, qint32* ndop00, bool bTx, QString jpleph)
{
  double azsun,elsun,azmoon,elmoon,azmoondx,elmoondx;
  double ramoon,decmoon,dgrd,poloffset,xnr,techo,width1,width2;
  int ntsky;
  QString date = t.date().toString("yyyy MMM dd").trimmed ();
  QString utc = t.time().toString().trimmed ();
  int nyear=t.date().year();
  int month=t.date().month();
  int nday=t.date().day();
  int nhr=t.time().hour();
  int nmin=t.time().minute();
  double sec=t.time().second() + 0.001*t.time().msec();
  double uth=nhr + nmin/60.0 + sec/3600.0;
  if(freqMoon < 1) freqMoon=144000000;
  int nfreq=freqMoon/1000000;
  double freq8=(double)freqMoon;

  QDir writable = QStandardPaths::writableLocation (QStandardPaths::DataLocation);
  QString AzElFileName = QDir::toNativeSeparators(writable.absoluteFilePath ("azel.dat"));

  astrosub_(&nyear, &month, &nday, &uth, &freq8, mygrid.toLatin1(),
            hisgrid.toLatin1(), &azsun, &elsun, &azmoon, &elmoon,
            &azmoondx, &elmoondx, &ntsky, ndop, ndop00, &ramoon, &decmoon,
            &dgrd, &poloffset, &xnr, &techo, &width1, &width2, &bTx,
            AzElFileName.toLatin1(), jpleph.toLatin1(), 6, 6,
            AzElFileName.length(), jpleph.length());

  QString message;
  {
    QTextStream out {&message};
    out
      << " " << date << "\n"
      "UTC: " << utc << "\n"
      << fixed
      << qSetFieldWidth (6)
      << qSetRealNumberPrecision (1)
      << "Az:     " << azmoon << "\n"
      "El:     " << elmoon << "\n"
      "SelfDop:" << *ndop00 << "\n"
      "Width:  " << int(width1) << "\n"
      << qSetRealNumberPrecision (2)
      << "Delay:  " << techo << "\n"
      << qSetRealNumberPrecision (1)
      << "DxAz:   " << azmoondx << "\n"
      "DxEl:   " << elmoondx << "\n"
      "DxDop:  " << *ndop << "\n"
      "DxWid:  " << int(width2) << "\n"
      "Dec:    " << decmoon << "\n"
      "SunAz:  " << azsun << "\n"
      "SunEl:  " << elsun << "\n"
      "Freq:   " << nfreq << "\n"
      "Tsky:   " << ntsky << "\n"
      "MNR:    " << xnr << "\n"
      "Dgrd:   " << dgrd;
  }
  ui_->text_label->setText(message);

  /*
  static QFile f {QDir {QStandardPaths::writableLocation (
            QStandardPaths::DataLocation)}.absoluteFilePath ("azel.dat")};
  if (!f.open (QIODevice::WriteOnly | QIODevice::Text)) {
    QMessageBox mb;
    mb.setText ("Cannot open \"" + f.fileName () + "\" for writing:" + f.errorString ());
    mb.exec();
    return;
  }
  {
    QTextStream out {&f};
    out << fixed
        << qSetRealNumberPrecision (1)
        << qSetPadChar ('0')
        << right
        << qSetFieldWidth (2) << nhr
        << qSetFieldWidth (0) << ':'
        << qSetFieldWidth (2) << nmin
        << qSetFieldWidth (0) << ':'
        << qSetFieldWidth (2) << isec
        << qSetFieldWidth (0) << ','
        << qSetFieldWidth (5) << azmoon
        << qSetFieldWidth (0) << ','
        << qSetFieldWidth (5) << elmoon
        << qSetFieldWidth (0) << ",Moon\n"
        << qSetFieldWidth (2) << nhr
        << qSetFieldWidth (0) << ':'
        << qSetFieldWidth (2) << nmin
        << qSetFieldWidth (0) << ':'
        << qSetFieldWidth (2) << isec
        << qSetFieldWidth (0) << ','
        << qSetFieldWidth (5) << azsun
        << qSetFieldWidth (0) << ','
        << qSetFieldWidth (5) << elsun
        << qSetFieldWidth (0) << ",Sun\n"
        << qSetFieldWidth (2) << nhr
        << qSetFieldWidth (0) << ':'
        << qSetFieldWidth (2) << nmin
        << qSetFieldWidth (0) << ':'
        << qSetFieldWidth (2) << isec
        << qSetFieldWidth (0) << ','
        << qSetFieldWidth (5) << 0.
        << qSetFieldWidth (0) << ','
        << qSetFieldWidth (5) << 0.
        << qSetFieldWidth (0) << ",Sun\n"
        << qSetPadChar (' ')
        << qSetFieldWidth (4) << nfreq
        << qSetFieldWidth (0) << ','
        << qSetFieldWidth (6) << ndop
        << qSetFieldWidth (0) << ",Doppler";
  }
  f.close();
  */
}

void Astro::on_cbDopplerTracking_toggled(bool b)
{
  QRect g=this->geometry();
  if(b) {
    g.setWidth(430);
  } else {
    g.setWidth(200);
  }
  this->setGeometry(g);
  m_bDopplerTracking=b;
}

void Astro::on_rbFullTrack_clicked()
{
  m_DopplerMethod=1;
}

void Astro::on_rbConstFreqOnMoon_clicked()
{
  m_DopplerMethod=2;
}

void Astro::on_rbNoDoppler_clicked()
{
  m_DopplerMethod=0;
}

void Astro::on_rb1Hz_clicked()
{
  m_stepHz=1;
}

void Astro::on_rb10Hz_clicked()
{
  m_stepHz=10;

}

void Astro::on_rb100Hz_clicked()
{
  m_stepHz=100;
}

void Astro::on_cbTxAudioTrack_toggled(bool b)
{
  m_bTxAudioTrack=b;
}

void Astro::on_kHzSpinBox_valueChanged(int n)
{
  m_kHz=n;
}

void Astro::on_HzSpinBox_valueChanged(int n)
{
  m_Hz=n;
}
