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
#include "Configuration.hpp"
#include "SettingsGroup.hpp"
#include "qt_helpers.hpp"

#include "ui_astro.h"
#include "moc_astro.cpp"

Astro::Astro(QSettings * settings, Configuration const * configuration, QWidget * parent)
  : QWidget {parent, Qt::Dialog | Qt::WindowCloseButtonHint | Qt::WindowMinimizeButtonHint}
  , settings_ {settings}
  , configuration_ {configuration}
  , ui_ {new Ui::Astro}
  , m_bRxAudioTrack {false}
  , m_bTxAudioTrack {false}
  , m_DopplerMethod {0}
  , m_kHz {0}
  , m_Hz {0}
  , m_stepHz {1}
{
  ui_->setupUi (this);
  setWindowTitle (QApplication::applicationName () + " - " + tr ("Astronomical Data"));
  setStyleSheet ("QWidget {background: white;}");
  connect (ui_->cbDopplerTracking, &QAbstractButton::toggled, ui_->doppler_widget, &QWidget::setVisible);
  connect (ui_->cbDopplerTracking, &QAbstractButton::toggled, this, &Astro::doppler_tracking_toggled);
  read_settings ();
  ui_->text_label->clear ();
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
  SettingsGroup g (settings_, "Astro");
  ui_->cbDopplerTracking->setChecked (settings_->value ("DopplerTracking",false).toBool ());
  ui_->doppler_widget->setVisible (ui_->cbDopplerTracking->isChecked ());
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
}

void Astro::write_settings ()
{
  SettingsGroup g (settings_, "Astro");
  settings_->setValue ("DopplerTracking", ui_->cbDopplerTracking->isChecked ());
  settings_->setValue ("DopplerMethod",m_DopplerMethod);
  settings_->setValue ("StepHz",m_stepHz);
  settings_->setValue ("kHzAdd",m_kHz);
  settings_->setValue ("RxAudioTrack",m_bRxAudioTrack);
  settings_->setValue ("TxAudioTrack",m_bTxAudioTrack);
  settings_->setValue ("window/pos", pos ());
}

auto Astro::astroUpdate(QDateTime const& t, QString const& mygrid, QString const& hisgrid, Frequency freq,
                        bool dx_is_self, bool bTx) -> FrequencyDelta
{
  Frequency freq_moon {freq + 1000 * m_kHz + m_Hz};
  double azsun,elsun,azmoon,elmoon,azmoondx,elmoondx;
  double ramoon,decmoon,dgrd,poloffset,xnr,techo,width1,width2;
  int ntsky;
  QString date {t.date().toString("yyyy MMM dd").trimmed ()};
  QString utc {t.time().toString().trimmed ()};
  int nyear {t.date().year()};
  int month {t.date().month()};
  int nday {t.date().day()};
  int nhr {t.time().hour()};
  int nmin {t.time().minute()};
  double sec {t.time().second() + 0.001*t.time().msec()};
  double uth {nhr + nmin/60.0 + sec/3600.0};
  if(freq_moon < 1) freq_moon = 144000000;
  int nfreq {static_cast<int> (freq_moon / 1000000u)};
  double freq8 {static_cast<double> (freq_moon)};
  auto const& AzElFileName = QDir::toNativeSeparators (configuration_->azel_directory ().absoluteFilePath ("azel.dat"));
  auto const& jpleph = configuration_->data_dir ().absoluteFilePath ("JPLEPH");
  int ndop;
  int ndop00;

  astrosub_(&nyear, &month, &nday, &uth, &freq8, mygrid.toLatin1().constData(),
            hisgrid.toLatin1().constData(), &azsun, &elsun, &azmoon, &elmoon,
            &azmoondx, &elmoondx, &ntsky, &ndop, &ndop00, &ramoon, &decmoon,
            &dgrd, &poloffset, &xnr, &techo, &width1, &width2, &bTx,
            AzElFileName.toLatin1().constData(), jpleph.toLatin1().constData(), 6, 6,
            AzElFileName.length(), jpleph.length());

  QString message;
  {
    QTextStream out {&message};
    out << " " << date << "\n"
      "UTC: " << utc << "\n"
      << fixed
      << qSetFieldWidth (6)
      << qSetRealNumberPrecision (1)
      << "Az:     " << azmoon << "\n"
      "El:     " << elmoon << "\n"
      "SelfDop:" << ndop00 << "\n"
      "Width:  " << int(width1) << "\n"
      << qSetRealNumberPrecision (2)
      << "Delay:  " << techo << "\n"
      << qSetRealNumberPrecision (1)
      << "DxAz:   " << azmoondx << "\n"
      "DxEl:   " << elmoondx << "\n"
      "DxDop:  " << ndop << "\n"
      "DxWid:  " << int(width2) << "\n"
      "Dec:    " << decmoon << "\n"
      "SunAz:  " << azsun << "\n"
      "SunEl:  " << elsun << "\n"
      "Freq:   " << nfreq << "\n";
    if(nfreq>=50) {                     //Suppress data not relevant below VHF
      out << "Tsky:   " << ntsky << "\n"
        "MNR:    " << xnr << "\n"
        "Dgrd:   " << dgrd;
    }
  }
  ui_->text_label->setText(message);

  FrequencyDelta astro_correction {0};
  if (ui_->cbDopplerTracking->isChecked ()) {
    switch (m_DopplerMethod)
      {
      case 1:
        // All Doppler correction done here; DX station stays at nominal dial frequency.
        if(dx_is_self) {
          astro_correction = m_stepHz*qRound(double(ndop00)/m_stepHz);
        } else {
          astro_correction = m_stepHz*qRound(double(ndop)/m_stepHz);
        }
        break;

      case 2:
        // Doppler correction to constant frequency on Moon
        astro_correction = m_stepHz*qRound(double(ndop00/2.0)/m_stepHz);
        break;
      }

    if (bTx) {
      astro_correction = 1000 * m_kHz + m_Hz - astro_correction;
    } else {
      if(dx_is_self && m_DopplerMethod==1) {
        astro_correction = 1000*m_kHz + m_Hz;
      } else {
        astro_correction += 1000*m_kHz + m_Hz;
      }
    }
  }
  return astro_correction;
}

void Astro::on_rbFullTrack_clicked()
{
  m_DopplerMethod = 1;
}

void Astro::on_rbConstFreqOnMoon_clicked()
{
  m_DopplerMethod = 2;
}

void Astro::on_rbNoDoppler_clicked()
{
  m_DopplerMethod = 0;
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

bool Astro::doppler_tracking () const
{
  return ui_->cbDopplerTracking->isChecked ();
}
