#ifndef WIDEGRAPH_H
#define WIDEGRAPH_H
#include <QDialog>

namespace Ui {
  class WideGraph;
}

class WideGraph : public QDialog
{
  Q_OBJECT

public:
  explicit WideGraph(QWidget *parent = 0);
  ~WideGraph();

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
  void   setFmin(int n);
  void   setPalette(QString palette);
  void   setFsample(int n);
  void   setPeriod(int ntrperiod, int nsps);
  void   setTxFreq(int n);
  void   setMode(QString mode);
  void   setModeTx(QString modeTx);
  void   setSlope(double d);
  void   setLockTxFreq(bool b);
  double getSlope();
  double fGreen();

  qint32 m_rxFreq;
  qint32 m_txFreq;

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

private slots:
  void on_waterfallAvgSpinBox_valueChanged(int arg1);
  void on_freqSpanSpinBox_valueChanged(int arg1);
  void on_zeroSpinBox_valueChanged(int arg1);
  void on_gainSpinBox_valueChanged(int arg1);
  void on_spec2dComboBox_currentIndexChanged(const QString &arg1);
  void on_fMinSpinBox_valueChanged(int n);
  void on_slopeSpinBox_valueChanged(double d);

private:
  double m_slope;
  double m_dialFreq;

  qint32 m_waterfallAvg;
  qint32 m_fSample;
  qint32 m_TRperiod;
  qint32 m_nsps;
  qint32 m_ntr0;
  qint32 m_fMin;
  qint32 m_fMax;

  bool   m_lockTxFreq;

  QString m_mode;
  QString m_modeTx;

  Ui::WideGraph *ui;
};

#ifdef WIN32
extern int set570(double freq_MHz);
#endif

#endif // WIDEGRAPH_H
