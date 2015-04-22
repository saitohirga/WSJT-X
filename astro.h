// -*- Mode: C++ -*-
#ifndef ASTRO_H
#define ASTRO_H

#include <QWidget>
#include <QDir>

class QSettings;

namespace Ui {
  class Astro;
}

class Astro final
  : public QWidget
{
  Q_OBJECT;

private:
  Q_DISABLE_COPY (Astro);

public:
  explicit Astro(QSettings * settings, QWidget * parent = nullptr);
  ~Astro ();
  void astroUpdate(QDateTime t, QString mygrid, QString hisgrid, qint64 freqMoon,
                   qint32* ndop, qint32 *ndop00);

  bool m_bDopplerTracking;
  bool m_bRxAudioTrack;
  bool m_bTxAudioTrack;

  qint32 m_DopplerMethod;
  qint32 m_kHz;
  qint32 m_stepHz;

protected:
  void closeEvent (QCloseEvent *) override;

private slots:
  void on_cbDopplerTracking_toggled(bool b);
  void on_rbConstFreqOnMoon_clicked();
  void on_rbFullTrack_clicked();
  void on_rbNoDoppler_clicked();
  void on_rb1Hz_clicked();
  void on_rb10Hz_clicked();
  void on_rb100Hz_clicked();
  void on_cbRxTrack_toggled(bool b);
  void on_cbTxTrack_toggled(bool b);
  void on_kHzSpinBox_valueChanged(int n);

private:
  void read_settings ();
  void write_settings ();

  QSettings * settings_;
//  QScopedPointer<Ui::Astro> ui_;
  Ui::Astro *ui_;
};

extern "C" {
  void astrosub_(int* nyear, int* month, int* nday, double* uth, double* freqMoon,
                 const char* mygrid, const char* hisgrid, double* azsun,
                 double* elsun, double* azmoon, double* elmoon, double* azmoondx,
                 double* elmoondx, int* ntsky, int* ndop, int* ndop00,
                 double* ramoon, double* decmoon, double* dgrd, double* poloffset,
                 double* xnr, double* techo, int len1, int len2);
}

#endif // ASTRO_H
