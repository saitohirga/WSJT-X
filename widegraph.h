// -*- Mode: C++ -*-
#ifndef WIDEGRAPH_H
#define WIDEGRAPH_H

#include <QDialog>
#include <QScopedPointer>
#include <QDir>

#include "WFPalette.hpp"

namespace Ui {
  class WideGraph;
}

class QSettings;
class Configuration;

class WideGraph : public QDialog
{
  Q_OBJECT

public:
  explicit WideGraph(QSettings *, QWidget *parent = 0);
  ~WideGraph ();

  void   dataSink2(float s[], float df3, int ihsym, int ndiskdata);
  void   setRxFreq(int n);
  int    rxFreq();
  int    nSpan();
  int    nStartFreq();
  int    getFmin();
  int    getFmax();
  float  fSpan();
  void   saveSettings();
  void   setRxRange(int fMin);
  void   setFsample(int n);
  void   setPeriod(int ntrperiod, int nsps);
  void   setTxFreq(int n);
  void   setMode(QString mode);
  void   setModeTx(QString modeTx);
  void   setLockTxFreq(bool b);
  double fGreen();
  bool   flatten();

signals:
  void freezeDecode2(int n);
  void f11f12(int n);
  void setXIT2(int n);
  void setFreq3(int rxFreq, int txFreq);

public slots:
  void wideFreezeDecode(int n);
  void setFreq2(int rxFreq, int txFreq);
  void setDialFreq(double d);

protected:
  virtual void keyPressEvent( QKeyEvent *e );
  void closeEvent (QCloseEvent *);

private slots:
  void on_waterfallAvgSpinBox_valueChanged(int arg1);
  void on_freqSpanSpinBox_valueChanged(int arg1);
  void on_zeroSpinBox_valueChanged(int arg1);
  void on_gainSpinBox_valueChanged(int arg1);
  void on_spec2dComboBox_currentIndexChanged(const QString &arg1);
  void on_fMinSpinBox_valueChanged(int n);
  void on_fStartSpinBox_valueChanged(int n);
  void on_paletteComboBox_activated(const QString &palette);
  void on_cbFlatten_toggled(bool b);
  void on_adjust_palette_push_button_clicked (bool);

private:
  void   readPalette();

  QScopedPointer<Ui::WideGraph> ui;
  QSettings * m_settings;
  QDir m_palettes_path;
  WFPalette m_userPalette;

  qint32 m_rxFreq;
  qint32 m_txFreq;

  double m_dialFreq;

  qint32 m_waterfallAvg;
  qint32 m_fSample;
  qint32 m_TRperiod;
  qint32 m_nsps;
  qint32 m_ntr0;
  qint32 m_fMin;
  qint32 m_fMax;

  bool   m_lockTxFreq;
  bool   m_bFlatten;

  QString m_mode;
  QString m_modeTx;
  QString m_waterfallPalette;
};

#endif // WIDEGRAPH_H
