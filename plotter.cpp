#include "plotter.h"
#include <math.h>
#include <QDebug>

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
  m_nSpan=2;                         //used for FFT bins/pixel
  m_fSpan=(float)m_nSpan;
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
  if( m_Size != size() ) {  //if changed, resize pixmaps to new screensize
    m_Size = size();
    m_w = m_Size.width();
    m_h = m_Size.height();
    m_h1 = (100-m_Percent2DScreen)*(m_Size.height())/100;
    m_h2 = (m_Percent2DScreen)*(m_Size.height())/100;

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

void CPlotter::paintEvent(QPaintEvent *)                    // paintEvent()
{
  if(m_paintEventBusy) return;
  m_paintEventBusy=true;
  QPainter painter(this);
  painter.drawPixmap(0,0,m_ScalePixmap);
  painter.drawPixmap(0,30,m_WaterfallPixmap);
  painter.drawPixmap(0,m_h1,m_2DPixmap);
  m_paintEventBusy=false;
}

void CPlotter::draw(float swide[])             //draw()
{
  int j,y2;
  float y;

  double gain = pow(10.0,0.05*(m_plotGain+7));

//move current data down one line (must do this before attaching a QPainter object)
  m_WaterfallPixmap.scroll(0,1,0,0,m_w,m_h1);
  QPainter painter1(&m_WaterfallPixmap);
  m_2DPixmap = m_OverlayPixmap.copy(0,0,m_w,m_h2);
  QPainter painter2D(&m_2DPixmap);

  painter2D.setPen(Qt::green);

  QPoint LineBuf[MAX_SCREENSIZE];
  j=0;

  int iz=XfromFreq(5000.0);
  m_fMax=FreqfromX(iz);
  for(int i=0; i<iz; i++) {
    if(i>iz) swide[i]=0;
    y=0.0;
    if(swide[i]>0.0) y = 10.0*log10(swide[i]);
    int y1 = 5.0*gain*y + 10*(m_plotZero-4);
    if (y1<0) y1=0;
    if (y1>254) y1=254;
    if (swide[i]>1.e29) y1=255;
    painter1.setPen(m_ColorTbl[y1]);
    painter1.drawPoint(i,0);
    y2=0;
    if(m_bCurrent) y2 = 0.4*gain*y - 15;
    if(m_bCumulative) {
      float sum=0.0;
      int j=m_binsPerPixel*i;
      for(int k=0; k<m_binsPerPixel; k++) {
        sum+=jt9com_.savg[j++];
      }
      y2=gain*6.0*log10(sum/m_binsPerPixel) - 10.0;
    }
    y2 += m_plotZero;
    if(i==iz-1) painter2D.drawPolyline(LineBuf,j);
    LineBuf[j].setX(i);
    LineBuf[j].setY(m_h-(y2+0.8*m_h));
    j++;
  }

  if(swide[0]>1.0e29) m_line=0;
  m_line++;
  if(m_line == 13) {
    UTCstr();
    if(m_palette=="Gray1") {
      painter1.setPen(Qt::red);
    } else {
      painter1.setPen(Qt::white);
    }
    painter1.drawText(5,10,m_sutc);
  }
  update();                              //trigger a new paintEvent
}

void CPlotter::UTCstr()
{
  int ihr,imin;
  if(jt9com_.ndiskdat != 0) {
    ihr=jt9com_.nutc/100;
    imin=jt9com_.nutc % 100;
  } else {
    qint64 ms = QDateTime::currentMSecsSinceEpoch() % 86400000;
    imin=ms/60000;
    ihr=imin/60;
    imin=imin % 60;
    imin=imin - (imin % (m_TRperiod/60));
  }
  sprintf(m_sutc,"%2.2d:%2.2d",ihr,imin);
}

void CPlotter::DrawOverlay()                                 //DrawOverlay()
{
  if(m_OverlayPixmap.isNull()) return;
  if(m_WaterfallPixmap.isNull()) return;
  int w = m_WaterfallPixmap.width();
  int x,y,x1,x2;
//  int nHzDiv[11]={0,50,100,200,200,200,500,500,500,500,500};
  float pixperdiv;

  QRect rect;
  QPainter painter(&m_OverlayPixmap);
  painter.initFrom(this);
  QLinearGradient gradient(0, 0, 0 ,m_h2);  //fill background with gradient
  gradient.setColorAt(1, Qt::black);
  gradient.setColorAt(0, Qt::darkBlue);
  painter.setBrush(gradient);
  painter.drawRect(0, 0, m_w, m_h2);
  painter.setBrush(Qt::SolidPattern);

  double df = m_binsPerPixel*m_fftBinWidth;
  pixperdiv = m_freqPerDiv/df;
  y = m_h2 - m_h2/VERT_DIVS;
  m_hdivs = w*df/m_freqPerDiv + 0.9999;
  for( int i=1; i<m_hdivs; i++)                   //draw vertical grids
  {
    x = (int)( (float)i*pixperdiv );
    if(x >= 0 and x<=m_w) {
      painter.setPen(QPen(Qt::white, 1,Qt::DotLine));
      painter.drawLine(x, 0, x , y);
      painter.drawLine(x, m_h2-5, x , m_h2);
    }
  }

  pixperdiv = (float)m_h2 / (float)VERT_DIVS;
  painter.setPen(QPen(Qt::white, 1,Qt::DotLine));
  for( int i=1; i<VERT_DIVS; i++)                 //draw horizontal grids
  {
          y = (int)( (float)i*pixperdiv );
          painter.drawLine(0, y, w, y);
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
  int n=m_fSpan/10;
  m_freqPerDiv=10;
  if(n>25) m_freqPerDiv=50;
  if(n>70) m_freqPerDiv=100;
  if(n>140) m_freqPerDiv=200;
  if(n>310) m_freqPerDiv=500;
  m_hdivs = w*df/m_freqPerDiv + 0.9999;
  m_ScalePixmap.fill(Qt::white);
  painter0.drawRect(0, 0, w, 30);

//draw tick marks on upper scale
  pixperdiv = m_freqPerDiv/df;
  for( int i=1; i<m_hdivs; i++) {     //major ticks
    x = (int)( (float)i*pixperdiv );
    painter0.drawLine(x,18,x,30);
  }
  int minor=5;
  if(m_freqPerDiv==200) minor=4;
  for( int i=1; i<minor*m_hdivs; i++) {   //minor ticks
    x = i*pixperdiv/minor;
    painter0.drawLine(x,24,x,30);
  }

  //draw frequency values
  MakeFrequencyStrs();
  for( int i=0; i<=m_hdivs; i++) {
    if(0==i) {
      //left justify the leftmost text
      x = (int)( (float)i*pixperdiv);
      rect0.setRect(x,0, (int)pixperdiv, 20);
      painter0.drawText(rect0, Qt::AlignLeft|Qt::AlignVCenter,
                       m_HDivText[i]);
    }
    else if(m_hdivs == i) {
      //right justify the rightmost text
      x = (int)( (float)i*pixperdiv - pixperdiv);
      rect0.setRect(x,0, (int)pixperdiv, 20);
      painter0.drawText(rect0, Qt::AlignRight|Qt::AlignVCenter,
                       m_HDivText[i]);
    } else {
      //center justify the rest of the text
      x = (int)( (float)i*pixperdiv - pixperdiv/2);
      rect0.setRect(x,0, (int)pixperdiv, 20);
      painter0.drawText(rect0, Qt::AlignHCenter|Qt::AlignVCenter,
                       m_HDivText[i]);
    }
  }

  float bw=9.0*12000.0/m_nsps;
  if(m_modeTx=="JT65") bw=66.0*11025.0/4096.0;

  QPen pen0(Qt::green, 3);                 //Mark Rx Freq with green
  painter0.setPen(pen0);
  x1=XfromFreq(m_rxFreq);
  x2=XfromFreq(m_rxFreq+bw);
  painter0.drawLine(x1,24,x1,30);
  painter0.drawLine(x1,28,x2,28);
  painter0.drawLine(x2,24,x2,30);

  if(m_mode=="JT9+JT65") {
    QPen pen2(Qt::blue, 3);                //Mark the JT65 | JT9 divider
    painter0.setPen(pen2);
    x1=XfromFreq(m_fMin);
    if(x1<2) x1=2;
    x2=x1+30;
    painter0.drawLine(x1,8,x1,28);
  }

  QPen pen1(Qt::red, 3);                   //Mark Tx freq with red
  painter0.setPen(pen1);
  x1=XfromFreq(m_txFreq);
  x2=XfromFreq(m_txFreq+bw);
  painter0.drawLine(x1,17,x1,21);
  painter0.drawLine(x1,17,x2,17);
  painter0.drawLine(x2,17,x2,21);

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
  float freq;
  for(int i=0; i<=m_hdivs; i++) {
    freq = m_startFreq + i*m_freqPerDiv;
    m_HDivText[i].setNum((int)freq);
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

int CPlotter::getPlotZero()                               //getPlotZero()
{
  return m_plotZero;
}

void CPlotter::setPlotGain(int plotGain)                  //setPlotGain()
{
  m_plotGain=plotGain;
}

int CPlotter::getPlotGain()                               //getPlotGain()
{
  return m_plotGain;
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

int CPlotter::plotWidth(){return m_WaterfallPixmap.width();}
void CPlotter::UpdateOverlay() {DrawOverlay();}
void CPlotter::setDataFromDisk(bool b) {m_dataFromDisk=b;}

void CPlotter::setRxRange(int fMin)
{
  m_fMin=fMin;
}

void CPlotter::setBinsPerPixel(int n)                       // set nbpp
{
  m_binsPerPixel = n;
  DrawOverlay();                         //Redraw scales and ticks
  update();                              //trigger a new paintEvent}
}

int CPlotter::binsPerPixel()                                // get nbpp
{
  return m_binsPerPixel;
}

void CPlotter::setRxFreq(int x, bool bf)                       //setRxFreq()
{
  if(bf) {
    m_rxFreq=x;         // x is freq in Hz
    m_xClick=XfromFreq(m_rxFreq);
  } else {
    if(x<0) x=0;      // x is pixel number
    if(x>m_Size.width()) x=m_Size.width();
    m_rxFreq=int(FreqfromX(x)+0.5);
    m_xClick=x;
  }
  emit setFreq1(m_rxFreq,m_txFreq);
  DrawOverlay();
  update();
}

int CPlotter::rxFreq() {return m_rxFreq;}                //get rxFreq

void CPlotter::mousePressEvent(QMouseEvent *event)       //mousePressEvent
{
  int x=event->x();
  setRxFreq(x,false);                               // Wideband waterfall
  bool ctrl = (event->modifiers() & Qt::ControlModifier);
  int n=1;
  if(ctrl) n+=100;
  emit freezeDecode1(n);
  if(ctrl or m_lockTxFreq) setTxFreq(m_rxFreq);
}

void CPlotter::mouseDoubleClickEvent(QMouseEvent *event)  //mouse2click
{
//  int x=event->x();
//  setRxFreq(x,false);
  bool ctrl = (event->modifiers() & Qt::ControlModifier);
  int n=2;
  if(ctrl) n+=100;
  emit freezeDecode1(n);
}

void CPlotter::setNSpan(int n)                                  //setNSpan()
{
  m_nSpan=n;
}

void CPlotter::setPalette(QString palette)                      //setPalette()
{
  m_palette=palette;
  if(palette=="Linrad") {
    float twopi=6.2831853;
    float r,g,b,phi,x;
    for(int i=0; i<256; i++) {
      r=0.0;
      if(i>105 and i<=198) {
        phi=(twopi/4.0) * (i-105.0)/(198.0-105.0);
        r=sin(phi);
      } else if(i>=198) {
          r=1.0;
      }

      g=0.0;
      if(i>35 and i<198) {
        phi=(twopi/4.0) * (i-35.0)/(122.5-35.0);
        g=0.625*sin(phi);
      } else if(i>=198) {
        x=(i-186.0);
        g=-0.014 + 0.0144*x -0.00007*x*x +0.000002*x*x*x;
        if(g>1.0) g=1.0;
      }

      b=0.0;
      if(i<=117) {
        phi=(twopi/2.0) * i/117.0;
        b=0.4531*sin(phi);
      } else if(i>186) {
        x=(i-186.0);
        b=-0.014 + 0.0144*x -0.00007*x*x +0.000002*x*x*x;
        if(b>1.0) b=1.0;
      }
      m_ColorTbl[i].setRgb(int(255.0*r),int(255.0*g),int(255.0*b));
    }
    m_ColorTbl[255].setRgb(255,255,100);
    return;
  }

  if(palette=="CuteSDR") {
      for( int i=0; i<256; i++) {
      if( (i<43) )
        m_ColorTbl[i].setRgb( 0,0, 255*(i)/43);
      if( (i>=43) && (i<87) )
        m_ColorTbl[i].setRgb( 0, 255*(i-43)/43, 255 );
      if( (i>=87) && (i<120) )
        m_ColorTbl[i].setRgb( 0,255, 255-(255*(i-87)/32));
      if( (i>=120) && (i<154) )
        m_ColorTbl[i].setRgb( (255*(i-120)/33), 255, 0);
      if( (i>=154) && (i<217) )
        m_ColorTbl[i].setRgb( 255, 255 - (255*(i-154)/62), 0);
      if( (i>=217)  )
        m_ColorTbl[i].setRgb( 255, 0, 128*(i-217)/38);
    }
    m_ColorTbl[255].setRgb(255,255,100);
    return;
  }

  FILE* fp=NULL;
  if(palette=="Blue") fp=fopen("blue.dat","r");
  if(palette=="AFMHot") fp=fopen("afmhot.dat","r");
  if(palette=="Gray1") fp=fopen("gray1.dat","r");
  if(fp==NULL) {
    QMessageBox msgBox0;
    QString t="Error: Cannot find requested palette file.";
    msgBox0.setText(t);
    msgBox0.exec();
    return;
  }

  int n,r,g,b;
  float xr,xg,xb;
  for(int i=0; i<256; i++) {
    int nn=fscanf(fp,"%d%f%f%f",&n,&xr,&xg,&xb);
    r=255.0*xr + 0.5;
    g=255.0*xg + 0.5;
    b=255.0*xb + 0.5;
    m_ColorTbl[i].setRgb(r,g,b);
    if(nn==-999999) i++;                  //Silence compiler warning
  }
}

double CPlotter::fGreen()
{
  return m_fGreen;
}

void CPlotter::setNsps(int ntrperiod, int nsps)                                  //setNSpan()
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

void CPlotter::setTxFreq(int n)                                 //setTol()
{
  m_txFreq=n;
  emit setFreq1(m_rxFreq,m_txFreq);
  DrawOverlay();
  update();
}

void CPlotter::setMode(QString mode)
{
  m_mode=mode;
}

void CPlotter::setModeTx(QString modeTx)
{
  m_modeTx=modeTx;
}

int CPlotter::getFmax()
{
  return m_fMax;
}

void CPlotter::setDialFreq(double d)
{
  m_dialFreq=d;
  DrawOverlay();
  update();
}
