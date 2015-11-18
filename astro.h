// -*- Mode: C++ -*-
#ifndef ASTRO_H
#define ASTRO_H

#include <QWidget>
#include "Radio.hpp"

class QSettings;
class Configuration;
namespace Ui {
  class Astro;
}

class Astro final
  : public QWidget
{
  Q_OBJECT;

  using Frequency = Radio::Frequency;
  using FrequencyDelta = Radio::FrequencyDelta;

public:
  explicit Astro(QSettings * settings, Configuration const *, QWidget * parent = nullptr);
  ~Astro ();
  FrequencyDelta astroUpdate(QDateTime const& t, QString const& mygrid, QString const& hisgrid, Frequency frequency,
                             bool dx_is_self, bool bTx);
  bool doppler_tracking () const;
  bool trackVFO();
  Q_SIGNAL void doppler_tracking_toggled (bool);

protected:
  void closeEvent (QCloseEvent *) override;

private slots:
  void on_rbConstFreqOnMoon_clicked();
  void on_rbFullTrack_clicked();
  void on_rbNoDoppler_clicked();
  void on_rb1Hz_clicked();
  void on_rb10Hz_clicked();
  void on_rb100Hz_clicked();
  void on_cbTxAudioTrack_toggled(bool b);
  void on_kHzSpinBox_valueChanged(int n);
  void on_HzSpinBox_valueChanged(int n);
  void on_cbTrackVFO_toggled(bool b);

private:
  void read_settings ();
  void write_settings ();

  QSettings * settings_;
  Configuration const * configuration_;
  Ui::Astro * ui_;
  bool m_bRxAudioTrack;
  bool m_bTxAudioTrack;
  bool m_bTrackVFO;

  qint32 m_DopplerMethod;
  qint32 m_kHz;
  qint32 m_Hz;
  qint32 m_stepHz;
};

extern "C" {
  void astrosub_(int* nyear, int* month, int* nday, double* uth, double* freqMoon,
                 const char* mygrid, const char* hisgrid, double* azsun,
                 double* elsun, double* azmoon, double* elmoon, double* azmoondx,
                 double* elmoondx, int* ntsky, int* ndop, int* ndop00,
                 double* ramoon, double* decmoon, double* dgrd, double* poloffset,
                 double* xnr, double* techo, double* width1, double* width2,
                 bool* bTx, const char* AzElFileName, const char* jpleph,
                 int len1, int len2, int len3, int len4);
}

#endif // ASTRO_H
