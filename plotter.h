///////////////////////////////////////////////////////////////////////////
// Some code in this file and accompanying files is based on work by
// Moe Wheatley, AE4Y, released under the "Simplified BSD License".
// For more details see the accompanying file LICENSE_WHEATLEY.TXT
///////////////////////////////////////////////////////////////////////////

#ifndef PLOTTER_H
#define PLOTTER_H

#include <QtGui>
#include <QFrame>
#include <QImage>
#include <cstring>
#include "commons.h"

#define VERT_DIVS 7	//specify grid screen divisions
#define HORZ_DIVS 20

class CPlotter : public QFrame
{
  Q_OBJECT
public:
  explicit CPlotter(QWidget *parent = 0);
  ~CPlotter();

  QSize minimumSizeHint() const;
  QSize sizeHint() const;
  QColor  m_ColorTbl[256];
  int     m_plotZero;
  int     m_plotGain;
  qint32  m_DF;
  qint32  m_tol;

  void draw(float green[], int ig);	       //Update the graphics
  void SetRunningState(bool running);
  void setPlotZero(int plotZero);
  int  getPlotZero();
  void setPlotGain(int plotGain);
  int  getPlotGain();
  int  plotWidth();
  void UpdateOverlay();
  void setDataFromDisk(bool b);
  void setTol(int n);
  void DrawOverlay();
  int  DF();
  int  autoZero();
  void setPalette(QString palette);
  void set2Dspec(bool b);

signals:
  void freezeDecode0(int n);
  void freezeDecode1(int n);

protected:
  //re-implemented widget event handlers
  void paintEvent(QPaintEvent *event);
  void resizeEvent(QResizeEvent* event);

private:

  void MakeTimeStrs();
  int xFromTime(float f);
  float timeFromX(int x);
  qint64 RoundFreq(qint64 freq, int resolution);

  QPixmap m_WaterfallPixmap;
  QPixmap m_ZoomWaterfallPixmap;
  QPixmap m_2DPixmap;
  unsigned char m_zwf[32768*400];
  QPixmap m_ScalePixmap;
  QPixmap m_ZoomScalePixmap;
  QSize   m_Size;
  QString m_Str;
  QString m_HDivText[483];
  bool    m_Running;
  bool    m_paintEventBusy;
  bool    m_2Dspec;
  bool    m_paintAllZoom;
  double  m_CenterFreq;
  qint64  m_ZoomStartFreq;
  qint64  m_FreqOffset;
  qint32  m_dBStepSize;
  qint32  m_FreqUnits;
  qint32  m_hdivs;
  bool    m_dataFromDisk;
  char    m_sutc[5];
  qint32  m_line;
  qint32  m_hist1[256];
  qint32  m_hist2[256];
  qint32  m_z1;
  qint32  m_z2;
  qint32  m_nkhz;
  qint32  m_fSample;
  qint32  m_mode65;
  qint32  m_i0;
  qint32  m_xClick;

private slots:
  void mousePressEvent(QMouseEvent *event);
  void mouseDoubleClickEvent(QMouseEvent *event);
};

#endif // PLOTTER_H
