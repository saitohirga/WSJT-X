#include "plotter.h"
#include <math.h>
#include <QDebug>

#include "moc_plotter.cpp"

#define MAX_SCREENSIZE 2048

CPlotter::CPlotter(QWidget *parent) :                  //CPlotter Constructor
  QFrame(parent)
{
  setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
  setFocusPolicy(Qt::StrongFocus);
  setAttribute(Qt::WA_PaintOnScreen,false);
  setAutoFillBackground(false);
  setAttribute(Qt::WA_OpaquePaintEvent, false);
  setAttribute(Qt::WA_NoSystemBackground, true);

  m_startFreq = 0;
  m_fSpan=2000.0;
  m_hdivs = HORZ_DIVS;
  m_FreqUnits = 1;
  m_Running = false;
  m_paintEventBusy=false;
  m_WaterfallPixmap = QPixmap(0,0);
  m_2DPixmap = QPixmap(0,0);
  m_ScalePixmap = QPixmap(0,0);
  m_OverlayPixmap = QPixmap(0,0);
  m_Size = QSize(0,0);
  m_rxFreq = 1020;
  m_line = 0;
  m_fSample = 12000;
  m_nsps=6912;
  m_dBStepSize=10;
  m_Percent2DScreen = 30;	//percent of screen used for 2D display
  m_txFreq=0;
  m_fftBinWidth=1500.0/2048.0;
  m_bScaleOK=false;
}

CPlotter::~CPlotter() { }                                      // Destructor

QSize CPlotter::minimumSizeHint() const
{
  return QSize(50, 50);
}

QSize CPlotter::sizeHint() const
{
  return QSize(180, 180);
}

void CPlotter::resizeEvent(QResizeEvent* )                    //resizeEvent()
{
  if(!size().isValid()) return;
  if( m_Size != size() or (m_bReference != m_bReference0)) {
    m_Size = size();
    m_w = m_Size.width();
    m_h = m_Size.height();
    m_h2 = (m_Percent2DScreen)*(m_h)/100;
    if(m_h2>100) m_h2=100;
    if(m_bReference) m_h2=m_h-30;
    m_h1=m_h-m_h2;
    m_2DPixmap = QPixmap(m_Size.width(), m_h2);
    m_2DPixmap.fill(Qt::black);
    m_WaterfallPixmap = QPixmap(m_Size.width(), m_h1);
    m_OverlayPixmap = QPixmap(m_Size.width(), m_h2);
    m_OverlayPixmap.fill(Qt::black);

    m_WaterfallPixmap.fill(Qt::black);
    m_2DPixmap.fill(Qt::black);
    m_ScalePixmap = QPixmap(m_w,30);
    m_ScalePixmap.fill(Qt::white);
  }
  DrawOverlay();
}

void CPlotter::paintEvent(QPaintEvent *)                                // paintEvent()
{
  if(m_paintEventBusy) return;
  m_paintEventBusy=true;
  QPainter painter(this);
  painter.drawPixmap(0,0,m_ScalePixmap);
  painter.drawPixmap(0,30,m_WaterfallPixmap);
  painter.drawPixmap(0,m_h1,m_2DPixmap);
  m_paintEventBusy=false;
}

void CPlotter::draw(float swide[], bool bScroll)                            //draw()
{
  int j,j0;
  float y,y2,ymin;

  double fac = sqrt(m_binsPerPixel*m_waterfallAvg/15.0);
  double gain = fac*pow(10.0,0.02*m_plotGain);
  double gain2d = pow(10.0,0.02*(m_plot2dGain));

  if(m_bReference != m_bReference0) resizeEvent(NULL);
  m_bReference0=m_bReference;

//move current data down one line (must do this before attaching a QPainter object)
  if(bScroll) m_WaterfallPixmap.scroll(0,1,0,0,m_w,m_h1);
  QPainter painter1(&m_WaterfallPixmap);
  m_2DPixmap = m_OverlayPixmap.copy(0,0,m_w,m_h2);
  QPainter painter2D(&m_2DPixmap);
  if(!painter2D.isActive()) return;
  QFont Font("Arial");
  Font.setPointSize(12);
  QFontMetrics metrics(Font);
  Font.setWeight(QFont::Normal);
  painter2D.setFont(Font);

  if(m_bLinearAvg) {
    painter2D.setPen(Qt::yellow);
  } else if(m_bReference) {
    painter2D.setPen(Qt::red);
  } else {
    painter2D.setPen(Qt::green);
  }

  QPoint LineBuf[MAX_SCREENSIZE];
  j=0;
  j0=int(m_startFreq/m_fftBinWidth + 0.5);
  int iz=XfromFreq(5000.0);
  int jz=iz*m_binsPerPixel;
  m_fMax=FreqfromX(iz);

  if(bScroll) {
    flat4_(swide,&iz,&m_Flatten);
    flat4_(&jt9com_.savg[j0],&jz,&m_Flatten);
  }

  ymin=1.e30;
  if(swide[0]>1.e29 and swide[0]< 1.5e30) painter1.setPen(Qt::green);
  if(swide[0]>1.4e30) painter1.setPen(Qt::yellow);
  for(int i=0; i<iz; i++) {
    y=swide[i];
    if(y<ymin) ymin=y;
    int y1 = 10.0*gain*y + 10*m_plotZero +40;
    if (y1<0) y1=0;
    if (y1>254) y1=254;
    if (swide[i]<1.e29) painter1.setPen(g_ColorTbl[y1]);
    painter1.drawPoint(i,0);
  }

  float y2min=1.e30;
  float y2max=-1.e30;
  for(int i=0; i<iz; i++) {
    y=swide[i] - ymin;
    y2=0;
    if(m_bCurrent) y2 = gain2d*y + m_plot2dZero;            //Current

    if(bScroll) {
      float sum=0.0;
      int j=j0+m_binsPerPixel*i;
      for(int k=0; k<m_binsPerPixel; k++) {
        sum+=jt9com_.savg[j++];
      }
      m_sum[i]=sum;
    }
    if(m_bCumulative) y2=2.5*gain2d*(m_sum[i]/m_binsPerPixel + m_plot2dZero);
    if(m_Flatten==0) y2 += 15;                      //### could do better! ###

    if(m_bLinearAvg) {                                   //Linear Avg (yellow)
      float sum=0.0;
      int j=j0+m_binsPerPixel*i;
      for(int k=0; k<m_binsPerPixel; k++) {
        sum+=jt9w_.syellow[j++];
      }
      y2=gain2d*sum/m_binsPerPixel + m_plot2dZero;
    }

    if(i==iz-1) painter2D.drawPolyline(LineBuf,j);
    LineBuf[j].setX(i);
    LineBuf[j].setY(int(0.9*m_h2-y2*m_h2/70.0));
    if(y2<y2min) y2min=y2;
    if(y2>y2max) y2max=y2;
    j++;
  }

  if(swide[0]>1.0e29) m_line=0;
  m_line++;
  if(m_line == 13) {
    painter1.setPen(Qt::white);
    QString t;
    if(m_TRperiod < 60) {
      qint64 ms = QDateTime::currentMSecsSinceEpoch() % 86400000;
      int n=(ms/1000) % m_TRperiod;
      QDateTime t1=QDateTime::currentDateTimeUtc().addSecs(-n);
      t=t1.toString("hh:mm:ss") + "    " + m_rxBand;
    } else {
      t=QDateTime::currentDateTimeUtc().toString("hh:mm") + "    " + m_rxBand;
    }
    painter1.drawText(5,10,t);
  }

  if(m_mode=="JT4") {
    QPen pen3(Qt::yellow);                     //Mark freqs of JT4 single-tone msgs
    painter2D.setPen(pen3);
    Font.setWeight(QFont::Bold);
    painter2D.setFont(Font);
    int x1=XfromFreq(m_rxFreq);
    y=0.2*m_h2;
    painter2D.drawText(x1-4,y,"T");
    x1=XfromFreq(m_rxFreq+250);
    painter2D.drawText(x1-4,y,"M");
    x1=XfromFreq(m_rxFreq+500);
    painter2D.drawText(x1-4,y,"R");
    x1=XfromFreq(m_rxFreq+750);
    painter2D.drawText(x1-4,y,"73");
  }
  update();                    //trigger a new paintEvent
  m_bScaleOK=true;
}

void CPlotter::DrawOverlay()                                 //DrawOverlay()
{
  if(m_OverlayPixmap.isNull()) return;
  if(m_WaterfallPixmap.isNull()) return;
  int w = m_WaterfallPixmap.width();
  int x,y,x1,x2;
  float pixperdiv;

  double df = m_binsPerPixel*m_fftBinWidth;
  QRect rect;
  {
    QPainter painter(&m_OverlayPixmap);
    painter.initFrom(this);
    QLinearGradient gradient(0, 0, 0 ,m_h2);         //fill background with gradient
    gradient.setColorAt(1, Qt::black);
    gradient.setColorAt(0, Qt::darkBlue);
    painter.setBrush(gradient);
    painter.drawRect(0, 0, m_w, m_h2);
    painter.setBrush(Qt::SolidPattern);

    pixperdiv = m_freqPerDiv/df;
    m_hdivs = w*df/m_freqPerDiv + 1.9999;

    float xx0=float(m_startFreq)/float(m_freqPerDiv);
    xx0=xx0-int(xx0);
    int x0=xx0*pixperdiv+0.5;
    for( int i=1; i<m_hdivs; i++) {                  //draw vertical grids
      x = (int)((float)i*pixperdiv ) - x0;
      if(x >= 0 and x<=m_w) {
        painter.setPen(QPen(Qt::white, 1,Qt::DotLine));
        painter.drawLine(x, 0, x , m_h2);
      }
    }

    pixperdiv = (float)m_h2 / (float)VERT_DIVS;
    painter.setPen(QPen(Qt::white, 1,Qt::DotLine));
    for( int i=1; i<VERT_DIVS; i++) {                //draw horizontal grids
      y = (int)( (float)i*pixperdiv );
      painter.drawLine(0, y, w, y);
    }
  }

  QRect rect0;
  QPainter painter0(&m_ScalePixmap);
  painter0.initFrom(this);

  //create Font to use for scales
  QFont Font("Arial");
  Font.setPointSize(12);
  QFontMetrics metrics(Font);
  Font.setWeight(QFont::Normal);
  painter0.setFont(Font);
  painter0.setPen(Qt::black);

  if(m_binsPerPixel < 1) m_binsPerPixel=1;
  m_fSpan = w*df;
//  int n=m_fSpan/10;
  m_freqPerDiv=10;
  if(m_fSpan>100) m_freqPerDiv=20;
  if(m_fSpan>250) m_freqPerDiv=50;
  if(m_fSpan>500) m_freqPerDiv=100;
  if(m_fSpan>1000) m_freqPerDiv=200;
  if(m_fSpan>2500) m_freqPerDiv=500;
  m_hdivs = w*df/m_freqPerDiv + 0.9999;

  m_ScalePixmap.fill(Qt::white);
  painter0.drawRect(0, 0, w, 30);
  MakeFrequencyStrs();

//draw tick marks on upper scale
  pixperdiv = m_freqPerDiv/df;
  for( int i=0; i<m_hdivs; i++) {                    //major ticks
    x = (int)((m_xOffset+i)*pixperdiv );
    painter0.drawLine(x,18,x,30);
  }
  int minor=5;
  if(m_freqPerDiv==200) minor=4;
  for( int i=1; i<minor*m_hdivs; i++) {             //minor ticks
    x = i*pixperdiv/minor;
    painter0.drawLine(x,24,x,30);
  }

  //draw frequency values
  for( int i=0; i<=m_hdivs; i++) {
    x = (int)((m_xOffset+i)*pixperdiv - pixperdiv/2);
    rect0.setRect(x,0, (int)pixperdiv, 20);
    painter0.drawText(rect0, Qt::AlignHCenter|Qt::AlignVCenter,m_HDivText[i]);
  }

  float bw=9.0*12000.0/m_nsps;               //JT9

  if(m_mode=="JT4") {                        //JT4
    bw=3*11025.0/2520.0;                     //Max tone spacing (3/4 of actual BW)
    if(m_nSubMode==1) bw=2*bw;
    if(m_nSubMode==2) bw=4*bw;
    if(m_nSubMode==3) bw=9*bw;
    if(m_nSubMode==4) bw=18*bw;
    if(m_nSubMode==5) bw=36*bw;
    if(m_nSubMode==6) bw=72*bw;

    QPen pen0(Qt::green, 3);                 //Mark Tol range with green line
    painter0.setPen(pen0);
    x1=XfromFreq(m_rxFreq-m_tol);
    x2=XfromFreq(m_rxFreq+m_tol);
    painter0.drawLine(x1,29,x2,29);
    for(int i=0; i<4; i++) {
      x1=XfromFreq(m_rxFreq+bw*i/3.0);
      int j=24;
      if(i==0) j=18;
      painter0.drawLine(x1,j,x1,30);
    }
    QPen pen1(Qt::red, 3);                   //Mark Tx freq with red
    painter0.setPen(pen1);
    for(int i=0; i<4; i++) {
      x1=XfromFreq(m_txFreq+bw*i/3.0);
      painter0.drawLine(x1,12,x1,18);
    }
  }

  if(m_modeTx=="JT65") {                     //JT65
    bw=66.0*11025.0/4096.0;
    if(m_nSubMode==1) bw=2*bw;
    if(m_nSubMode==2) bw=4*bw;
  }


  QPen pen0(Qt::green, 3);                 //Mark Rx Freq with green
  painter0.setPen(pen0);
  if(m_mode=="WSPR-2") {                   //### WSPR-15 code needed here, too ###
    x1=XfromFreq(1400);
    x2=XfromFreq(1600);
    painter0.drawLine(x1,29,x2,29);
  }
  if(m_mode=="JT9" or m_mode=="JT65" or m_mode=="JT9+JT65") {
    x1=XfromFreq(m_rxFreq);
    x2=XfromFreq(m_rxFreq+bw);
    painter0.drawLine(x1,24,x1,30);
    painter0.drawLine(x1,28,x2,28);
    painter0.drawLine(x2,24,x2,30);
  }

  if(m_mode=="JT9" or m_mode=="JT65" or m_mode=="JT9+JT65" or
     m_mode.mid(0,4)=="WSPR") {
    QPen pen1(Qt::red, 3);                   //Mark Tx freq with red
    painter0.setPen(pen1);
    x1=XfromFreq(m_txFreq);
    x2=XfromFreq(m_txFreq+bw);
    if(m_mode=="WSPR-2") {                  //### WSPR-15 code needed here, too
      bw=4*12000.0/8192.0;                  //WSPR
      x1=XfromFreq(m_txFreq-0.5*bw);
      x2=XfromFreq(m_txFreq+0.5*bw);
    }
    painter0.drawLine(x1,17,x1,21);
    painter0.drawLine(x1,17,x2,17);
    painter0.drawLine(x2,17,x2,21);
  }

  if(m_mode=="JT9+JT65") {
    QPen pen2(Qt::blue, 3);                //Mark the JT65 | JT9 divider
    painter0.setPen(pen2);
    x1=XfromFreq(m_fMin);
    if(x1<2) x1=2;
    x2=x1+30;
    painter0.drawLine(x1,8,x1,28);
  }

  if(m_dialFreq>10.13 and m_dialFreq< 10.15) {
    float f1=1.0e6*(10.1401 - m_dialFreq);
    float f2=f1+200.0;
    x1=XfromFreq(f1);
    x2=XfromFreq(f2);
    if(x1<=m_w and x2>=0) {
      QPen pen1(QColor(255,165,0),3);             //Mark WSPR sub-band orange
      painter0.setPen(pen1);
      painter0.drawLine(x1,9,x2,9);
    }
  }
}

void CPlotter::MakeFrequencyStrs()                       //MakeFrequencyStrs
{
  int f=(m_startFreq+m_freqPerDiv-1)/m_freqPerDiv;
  f*=m_freqPerDiv;
  m_xOffset=float(f-m_startFreq)/m_freqPerDiv;
  for(int i=0; i<=m_hdivs; i++) {
    m_HDivText[i].setNum(f);
    f+=m_freqPerDiv;
  }
}

int CPlotter::XfromFreq(float f)                               //XfromFreq()
{
//  float w = m_WaterfallPixmap.width();
  int x = int(m_w * (f - m_startFreq)/m_fSpan + 0.5);
  if(x<0 ) return 0;
  if(x>m_w) return m_w;
  return x;
}

float CPlotter::FreqfromX(int x)                               //FreqfromX()
{
  return float(m_startFreq + x*m_binsPerPixel*m_fftBinWidth);
}

void CPlotter::SetRunningState(bool running)              //SetRunningState()
{
  m_Running = running;
}

void CPlotter::setPlotZero(int plotZero)                  //setPlotZero()
{
  m_plotZero=plotZero;
}

int CPlotter::plotZero()                                  //PlotZero()
{
  return m_plotZero;
}

void CPlotter::setPlotGain(int plotGain)                  //setPlotGain()
{
  m_plotGain=plotGain;
}

int CPlotter::plotGain()                                 //plotGain()
{
  return m_plotGain;
}

int CPlotter::plot2dGain()                                //plot2dGain
{
  return m_plot2dGain;
}

void CPlotter::setPlot2dGain(int n)                       //setPlot2dGain
{
  m_plot2dGain=n;
  update();
}

int CPlotter::plot2dZero()                                //plot2dZero
{
  return m_plot2dZero;
}

void CPlotter::setPlot2dZero(int plot2dZero)              //setPlot2dZero
{
  m_plot2dZero=plot2dZero;
}

void CPlotter::setStartFreq(int f)                    //SetStartFreq()
{
  m_startFreq=f;
  resizeEvent(NULL);
  update();
}

int CPlotter::startFreq()                              //startFreq()
{
  return m_startFreq;
}

int CPlotter::plotWidth(){return m_WaterfallPixmap.width();}     //plotWidth
void CPlotter::UpdateOverlay() {DrawOverlay();}                  //UpdateOverlay
void CPlotter::setDataFromDisk(bool b) {m_dataFromDisk=b;}       //setDataFromDisk

void CPlotter::setRxRange(int fMin)                           //setRxRange
{
  m_fMin=fMin;
}

void CPlotter::setBinsPerPixel(int n)                         //setBinsPerPixel
{
  m_binsPerPixel = n;
  DrawOverlay();                         //Redraw scales and ticks
  update();                              //trigger a new paintEvent}
}

int CPlotter::binsPerPixel()                                   //binsPerPixel
{
  return m_binsPerPixel;
}

void CPlotter::setWaterfallAvg(int n)                         //setBinsPerPixel
{
  m_waterfallAvg = n;
}

void CPlotter::setRxFreq (int x)                               //setRxFreq
{
  m_rxFreq = x;         // x is freq in Hz
  DrawOverlay();
  update();
}

int CPlotter::rxFreq() {return m_rxFreq;}                      //rxFreq

void CPlotter::mousePressEvent(QMouseEvent *event)             //mousePressEvent
{
  int x=event->x();
  if(x<0) x=0;
  if(x>m_Size.width()) x=m_Size.width();
  bool ctrl = (event->modifiers() & Qt::ControlModifier);
  int freq = int(FreqfromX(x)+0.5);
  int tx_freq = m_txFreq;
  if (ctrl or m_lockTxFreq) tx_freq = freq;

  emit setFreq1 (freq, tx_freq);

  int n=1;
  if(ctrl) n+=100;
  emit freezeDecode1(n);
}

void CPlotter::mouseDoubleClickEvent(QMouseEvent *event)          //mouse2click
{
  bool ctrl = (event->modifiers() & Qt::ControlModifier);
  int n=2;
  if(ctrl) n+=100;
  emit freezeDecode1(n);
}

void CPlotter::setNsps(int ntrperiod, int nsps)                    //setNsps
{
  m_TRperiod=ntrperiod;
  m_nsps=nsps;
  m_fftBinWidth=1500.0/2048.0;
  if(m_nsps==15360)  m_fftBinWidth=1500.0/2048.0;
  if(m_nsps==40960)  m_fftBinWidth=1500.0/6144.0;
  if(m_nsps==82944)  m_fftBinWidth=1500.0/12288.0;
  if(m_nsps==252000) m_fftBinWidth=1500.0/32768.0;
  DrawOverlay();                         //Redraw scales and ticks
  update();                              //trigger a new paintEvent}
}

void CPlotter::setTxFreq(int n)                                 //setTxFreq
{
  m_txFreq=n;
  DrawOverlay();
  update();
}

void CPlotter::setMode(QString mode)                            //setMode
{
  m_mode=mode;
}

void CPlotter::setSubMode(int n)                                //setSubMode
{
  m_nSubMode=n;
}

void CPlotter::setModeTx(QString modeTx)                        //setModeTx
{
  m_modeTx=modeTx;
}

int CPlotter::Fmax()
{
  return m_fMax;
}

void CPlotter::setDialFreq(double d)
{
  m_dialFreq=d;
  DrawOverlay();
  update();
}

void CPlotter::setRxBand(QString band)
{
  m_rxBand=band;
}

void CPlotter::setFlatten(bool b)
{
  m_Flatten=0;
  if(b) m_Flatten=1;
}

void CPlotter::setTol(int n)                                 //setTol()
{
  m_tol=n;
  DrawOverlay();
}

void CPlotter::setColours(QVector<QColor> const& cl)
{
  g_ColorTbl = cl;
}
