#include "astro.h"

#include <stdio.h>

#include <QApplication>
#include <QFile>
#include <QTextStream>
#include <QMessageBox>
#include <QSettings>
#include <QDateTime>
#include <QFont>
#include <QFontDialog>
#include <QStandardPaths>
#include <QDir>

#include "commons.h"

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

  read_settings ();

  ui_->text_label->clear();
}

Astro::~Astro ()
{
  if (isVisible ())
    {
      write_settings ();
    }
}

void Astro::closeEvent (QCloseEvent * e)
{
  write_settings ();
  QWidget::closeEvent (e);
}

void Astro::read_settings ()
{
  settings_->beginGroup ("Astro");
  move (settings_->value ("window/pos", pos ()).toPoint ());
  QFont font;
  if (font.fromString (settings_->value ("font", ui_->text_label->font ().toString ()).toString ()))
    {
      ui_->text_label->setFont (font);
      adjustSize ();
    }
  settings_->endGroup ();
}

void Astro::write_settings ()
{
  settings_->beginGroup ("Astro");
  settings_->setValue ("window/pos", pos ());
  settings_->setValue ("font", ui_->text_label->font ().toString ());
  settings_->endGroup ();
}

void Astro::on_font_push_button_clicked (bool /* checked */)
{
  bool changed;
  ui_->text_label->setFont (QFontDialog::getFont (&changed
                                                  , ui_->text_label->font ()
                                                  , this
                                                  , tr ("WSJT-X Astro Text Font Chooser")
#if QT_VERSION >= 0x050201
                                                  , QFontDialog::MonospacedFonts
#endif
                                                  ));
  if (changed)
    {
      adjustSize ();
    }
}

void Astro::astroUpdate(QDateTime t, QString mygrid, QString hisgrid,
                        int fQSO, int nsetftx, int ntxFreq)
{
  static int ntxFreq0=-99;
  double azsun,elsun,azmoon,elmoon,azmoondx,elmoondx;
  double ramoon,decmoon,dgrd,poloffset,xnr,techo;
  int ntsky,ndop,ndop00;
  QString date = t.date().toString("yyyy MMM dd").trimmed ();
  QString utc = t.time().toString().trimmed ();
  int nyear=t.date().year();
  int month=t.date().month();
  int nday=t.date().day();
  int nhr=t.time().hour();
  int nmin=t.time().minute();
  double sec=t.time().second() + 0.001*t.time().msec();
  int isec=sec;
  double uth=nhr + nmin/60.0 + sec/3600.0;
  //  int nfreq=(int)datcom_.fcenter;
  int nfreq=10368;
  if(nfreq<10 or nfreq > 50000) nfreq=144;

  astrosub_(&nyear, &month, &nday, &uth, &nfreq, mygrid.toLatin1(),
            hisgrid.toLatin1(), &azsun, &elsun, &azmoon, &elmoon,
            &azmoondx, &elmoondx, &ntsky, &ndop, &ndop00,&ramoon, &decmoon,
            &dgrd, &poloffset, &xnr, &techo, 6, 6);

  QString message;
  {
    QTextStream out {&message};
    out
      << " " << date << "\n"
      "UTC: " << utc << "\n"
      << fixed
      << qSetFieldWidth (6)
      << qSetRealNumberPrecision (1)
      << "Az:    " << azmoon << "\n"
      "El:    " << elmoon << "\n"
      "MyDop: " << ndop00 << "\n"
      << qSetRealNumberPrecision (2)
      << "Delay: " << techo << "\n"
      << qSetRealNumberPrecision (1)
      << "DxAz:  " << azmoondx << "\n"
      "DxEl:  " << elmoondx << "\n"
      "DxDop: " << ndop << "\n"
      "Dec:   " << decmoon << "\n"
      "SunAz: " << azsun << "\n"
      "SunEl: " << elsun << "\n"
      "Freq:  " << nfreq << "\n"
      "Tsky:  " << ntsky << "\n"
      "MNR:   " << xnr << "\n"
      "Dgrd:  " << dgrd;
  }
  ui_->text_label->setText(message);

  static QFile f {QDir {QStandardPaths::writableLocation (QStandardPaths::DataLocation)}.absoluteFilePath ("azel.dat")};
  if (!f.open (QIODevice::WriteOnly | QIODevice::Text))
    {
    QMessageBox mb;
    mb.setText ("Cannot open \"" + f.fileName () + "\".");
    mb.exec();
    return;
  }
  int ndiff=0;
  if(ntxFreq != ntxFreq0) ndiff=1;
  ntxFreq0=ntxFreq;
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
        << qSetFieldWidth (0) << ",Doppler\n"
        << qSetFieldWidth (3) << fQSO
        << qSetFieldWidth (0) << ','
        << qSetFieldWidth (1) << nsetftx
        << qSetFieldWidth (0) << ",fQSO\n"
        << qSetFieldWidth (3) << ntxFreq
        << qSetFieldWidth (0) << ','
        << qSetFieldWidth (1) << ndiff
        << qSetFieldWidth (0) << ",fQSO2";
  }
  f.close();
}
