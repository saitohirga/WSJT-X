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

  double m_dForceCenterFreq;

  void   dataSink2(float s[], int nkhz, int ihsym, int ndiskdata,
                   uchar lstrong[]);
  int    QSOfreq();
  int    nSpan();
  int    nStartFreq();
  float  fSpan();
  void   saveSettings();
  void   setDF(int n);
  int    DF();
  int    Tol();
  void   setTol(int n);
  void   setFcal(int n);
  void   setPalette(QString palette);
  void   setFsample(int n);
  void   setMode65(int n);
  void   setPeriod(int ntrperiod, int nsps);
  double fGreen();

  qint32 m_qsoFreq;

signals:
  void freezeDecode2(int n);
  void f11f12(int n);

public slots:
  void wideFreezeDecode(int n);
  void initIQplus();

protected:
  virtual void keyPressEvent( QKeyEvent *e );

private slots:
  void on_waterfallAvgSpinBox_valueChanged(int arg1);
  void on_freqSpanSpinBox_valueChanged(int arg1);
  void on_freqOffsetSpinBox_valueChanged(int arg1);
  void on_zeroSpinBox_valueChanged(int arg1);
  void on_gainSpinBox_valueChanged(int arg1);
  void on_autoZeroPushButton_clicked();
//  void on_cbFcenter_stateChanged(int arg1);
  void on_fCenterLineEdit_editingFinished();
  void on_cbSpec2d_toggled(bool checked);

private:
  qint32 m_waterfallAvg;
  qint32 m_fCal;
  qint32 m_fSample;
  qint32 m_mode65;
  qint32 m_TRperiod;
  qint32 m_nsps;

  Ui::WideGraph *ui;
};

#ifdef WIN32
extern int set570(double freq_MHz);
#endif

#endif // WIDEGRAPH_H
