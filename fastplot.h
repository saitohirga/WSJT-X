///////////////////////////////////////////////////////////////////////////
// Some code in this file and accompanying files is based on work by
// Moe Wheatley, AE4Y, released under the "Simplified BSD License".
// For more details see the accompanying file LICENSE_WHEATLEY.TXT
///////////////////////////////////////////////////////////////////////////

#ifndef FPLOTTER_H
#define FPLOTTER_H

#include <QtWidgets>
#include <QFrame>
#include <QImage>
#include <cstring>

class FPlotter : public QFrame
{
  Q_OBJECT
public:
  explicit FPlotter(QWidget *parent = 0);
  ~FPlotter();

  qint32  m_w;
  qint32  m_plotZero;
  qint32  m_plotGain;
  qint32  m_greenGain;
  qint32  m_greenZero;
  qint32  m_x0;
  qint32  m_x1;
  qint32  m_y0;

  void draw();		                                    //Update the Fast plot
  void setPlotZero(int plotZero);
  void setPlotGain(int plotGain);
  void setGreenZero(int n);
  void drawScale();

signals:
  void fastPick1(int x0, int x1, int y);

protected:
  //re-implemented widget event handlers
  void paintEvent(QPaintEvent *event);
//  void resizeEvent(QResizeEvent* event);

private slots:
  void mousePressEvent(QMouseEvent *event);

private:

  void MakeTimeStrs();
  int XfromTime(float t);
  float TimefromX(int x);
  qint64 RoundFreq(qint64 freq, int resolution);

  QPixmap m_HorizPixmap;
  QPixmap m_ScalePixmap;
  QString m_HDivText[483];
  QString m_t;
  QString m_t0;

  double  m_pixPerSecond;

  qint32  m_hdivs;
  qint32  m_h;
  qint32  m_h1;
  qint32  m_h2;
  qint32  m_jh0;

  bool    m_bPaint2;
};

extern float fast_green[703];
extern float fast_green2[703];
extern float fast_s[44992];                                    //44992=64*703
extern float fast_s2[44992];
extern int   fast_jh;
extern int   fast_jh2;
extern QVector<QColor> g_ColorTbl;

#endif // FPLOTTER_H
