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
  explicit Astro(QSettings * settings, QDir const& dataPath, QWidget * parent = nullptr);
  ~Astro ();

  void astroUpdate(QDateTime t, QString mygrid, QString hisgrid,
                   int fQSO, int nsetftx, int ntxFreq);

  Q_SLOT void on_font_push_button_clicked (bool);

protected:
  void closeEvent (QCloseEvent *) override;

private:
  void read_settings ();
  void write_settings ();

  QSettings * settings_;
  QScopedPointer<Ui::Astro> ui_;
  QDir data_path_;
};

extern "C" {
  void astrosub_(int* nyear, int* month, int* nday, double* uth, int* nfreq,
                 const char* mygrid, const char* hisgrid, double* azsun,
                 double* elsun, double* azmoon, double* elmoon, double* azmoondx,
                 double* elmoondx, int* ntsky, int* ndop, int* ndop00,
                 double* ramoon, double* decmoon, double* dgrd, double* poloffset,
                 double* xnr, double* techo, int len1, int len2);
}

#endif // ASTRO_H
