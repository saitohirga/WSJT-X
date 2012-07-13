#include "plotter.h"
#include <math.h>
#include <QDebug>
#include <algorithm>

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

  m_hdivs = HORZ_DIVS;
  m_FreqUnits = 1;
  m_Running = false;
  m_paintEventBusy=false;
  m_WaterfallPixmap = QPixmap(0,0);
  m_ZoomWaterfallPixmap = QPixmap(0,0);
  m_2DPixmap = QPixmap(0,0);
  m_ScalePixmap = QPixmap(0,0);
  m_ZoomScalePixmap = QPixmap(0,0);
  m_Size = QSize(0,0);
  m_line = 0;
  m_fSample = 96000;
  m_paintAllZoom = false;
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
  if( m_Size != size() ) {
    //if changed, resize pixmaps to new screensize
    m_Size = size();
    int w = m_Size.width();
    int h = (m_Size.height()-60)/2;
    m_WaterfallPixmap = QPixmap(w,h);
    m_ZoomWaterfallPixmap = QPixmap(w,h);
    m_2DPixmap = QPixmap(w,h);
    m_WaterfallPixmap.fill(Qt::black);
    m_ZoomWaterfallPixmap.fill(Qt::black);
    m_2DPixmap.fill(Qt::black);
    memset(m_zwf,0,32768*h);
    m_ScalePixmap = QPixmap(w,30);
    m_ZoomScalePixmap = QPixmap(w,30);    //(no change on resize...)
    m_ScalePixmap.fill(Qt::white);
//    m_ZoomScalePixmap.fill(Qt::yellow);
    m_ZoomScalePixmap.fill(Qt::black);
  }
  DrawOverlay();
}

void CPlotter::paintEvent(QPaintEvent *)                    // paintEvent()
{
  static int x00=-99;

  if(m_paintEventBusy) return;
  m_paintEventBusy=true;
  QPainter painter(this);
  int w = m_Size.width();
  int h = (m_Size.height()-60)/2;
  painter.drawPixmap(0,0,m_ScalePixmap);
  painter.drawPixmap(0,30,m_WaterfallPixmap);
  if(true) {
//    painter.drawPixmap(0,h+30,m_ScalePixmap);
    painter.drawPixmap(0,h+60,m_2DPixmap);
    m_paintEventBusy=false;
    return;
  }

  painter.drawPixmap(0,h+30,m_ZoomScalePixmap);
  painter.drawPixmap(0,h+60,m_ZoomWaterfallPixmap);

  QRect target(0,h+30,w,30);           // (x,y,width,height)
  QRect source(0,0,w,30);
  painter.drawPixmap(target,m_ZoomScalePixmap,source);

  int x0=0;
  QPainter painter2(&m_ZoomWaterfallPixmap);
  for(int i=0; i<w; i++) {                      //Paint the top row
    painter2.setPen(m_ColorTbl[m_zwf[x0+i]]);
    painter2.drawPoint(i,0);
  }
  m_paintAllZoom=false;
  x00=x0;

  QRect target2(0,h+60,w,h);           // (x,y,width,height)
  QRect source2(0,0,w,h);
  painter.drawPixmap(target2,m_ZoomWaterfallPixmap,source2);
  m_paintEventBusy=false;
}

void CPlotter::draw(float green[], int ig)                       //draw()
{
  int i,j,w,h;
  float y;
  int y1;
  static int ig0=99999;

  w = m_WaterfallPixmap.width();
  h = m_WaterfallPixmap.height();
  if(ig<ig0) {
    m_WaterfallPixmap.fill(Qt::black);
    m_ZoomWaterfallPixmap.fill(Qt::black);
    m_2DPixmap.fill(Qt::black);
  }
  ig0=ig;

  double gain = pow(10.0,0.05*(m_plotGain+7));
  QPainter painter1(&m_WaterfallPixmap);
  QPainter painter2D(&m_2DPixmap);
  painter2D.setPen(Qt::green);
  QRect tmp(0,0,w,h);
  painter2D.fillRect(tmp,Qt::black);
  QPoint LineBuf[MAX_SCREENSIZE];

  for(i=0; i<256; i++) {                     //Zero the histograms
    m_hist1[i]=0;
    m_hist2[i]=0;
  }


  int kline=mscom_.kline;

  for(i=0; i<h; i++) {
    if(2*i < 215) {
      if(m_2Dspec) {
        y=10.0*log10(0.5*(mscom_.s2[2*i-1] + mscom_.s2[2*i]));
        y1 = 5.0*gain*(y + 20 - m_plotZero);
      } else {
        y=10.0*log10(std::max(mscom_.s1[2*i-1],mscom_.s1[2*i]));
        y1 = 5.0*gain*(y + 51 - m_plotZero);
      }
    } else {
      y1=0;
    }
    if (y1<0) y1=0;
    if (y1>254) y1=254;
    m_hist1[y1]++;
    painter1.setPen(m_ColorTbl[y1]);
    painter1.drawPoint(kline,h-i);
  }

  painter2D.setPen(Qt::green);
  j=0;
  for(i=0; i<ig; i++) {
    y = green[i];
    painter1.drawPoint(i,0);
    int y2 = 4*(y-m_plotZero);
    if (y2<0) y2=0;
    if (y2>254) y2=254;
    LineBuf[j].setX(i);
    LineBuf[j].setY(h-y2);
    j++;
  }
  painter2D.drawPolyline(LineBuf,ig);
  update();                              //trigger a new paintEvent
}

void CPlotter::DrawOverlay()                                 //DrawOverlay()
{
  if(m_WaterfallPixmap.isNull()) return;
  int w = m_WaterfallPixmap.width();
  int x;
  float pixperdiv;

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

//  m_binsPerPixel = m_nSpan * 32768.0/(w*0.001*m_fSample) + 0.5;
  double secPerDiv=5.0;
  double dt=2048.0/48000.0;
  m_hdivs = w*dt/secPerDiv;
//  m_fSpan = w*dt;
  m_ScalePixmap.fill(Qt::white);
  painter0.drawRect(0, 0, w, 30);

  //draw tick marks on wideband (upper) scale
  pixperdiv = secPerDiv/dt;
  for( int i=1; i<m_hdivs; i++) {     //major ticks
    x = (int)( (float)i*pixperdiv );
    painter0.drawLine(x,18,x,30);
  }
  for( int i=1; i<5*m_hdivs; i++) {   //minor ticks
    x = i*pixperdiv/5.0;
    painter0.drawLine(x,24,x,30);
  }

  //draw frequency values
  MakeTimeStrs();
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
}

void CPlotter::MakeTimeStrs()                       //MakeTimeStrs
{
  float StartFreq = 0.0;
  float freq;
  int i,j;
  int secPerDiv=5;

  if(m_hdivs > 100) {
    m_FreqUnits = 1;
    secPerDiv = 200;
    int w = m_WaterfallPixmap.width();
    float df=m_fSample/32768.0;
    StartFreq = -w*df/2;
    int n=StartFreq/secPerDiv;
    StartFreq=n*200;
    m_ZoomStartFreq = (int)StartFreq;
  }
  int numfractdigits = (int)log10((double)m_FreqUnits);

  if(1 == m_FreqUnits) {
    //if units is Hz then just output integer freq
    for(int i=0; i<=m_hdivs; i++) {
      freq = StartFreq/(float)m_FreqUnits;
      m_HDivText[i].setNum((int)freq);
      StartFreq += secPerDiv;
    }
    return;
  }
  //here if is fractional frequency values
  //so create max sized text based on frequency units
  for(int i=0; i<=m_hdivs; i++) {
    freq = StartFreq/(float)m_FreqUnits;
    m_HDivText[i].setNum(freq,'f', numfractdigits);
    StartFreq += secPerDiv;
  }
  //now find the division text with the longest non-zero digit
  //to the right of the decimal point.
  int max = 0;
  for(i=0; i<=m_hdivs; i++) {
    int dp = m_HDivText[i].indexOf('.');
    int l = m_HDivText[i].length()-1;
    for(j=l; j>dp; j--) {
      if(m_HDivText[i][j] != '0')
        break;
    }
    if( (j-dp) > max)
      max = j-dp;
  }
  //truncate all strings to maximum fractional length
  StartFreq = 0;
  for( i=0; i<=m_hdivs; i++) {
    freq = (float)StartFreq/(float)m_FreqUnits;
    m_HDivText[i].setNum(freq,'f', max);
    StartFreq += secPerDiv;
  }
}

int CPlotter::xFromTime(float t)                               //xFromTime()
{
  float w = m_WaterfallPixmap.width();
  int x = (int) w * t/30.0;
  if(x<0 ) return 0;
  if(x>(int)w) return m_WaterfallPixmap.width();
  return x;
}

float CPlotter::timeFromX(int x)                               //timeFromX()
{
  float w = m_WaterfallPixmap.width();
  float t = 30.0 * x/w;
  return t;
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

int CPlotter::plotWidth(){return m_WaterfallPixmap.width();}
void CPlotter::UpdateOverlay() {DrawOverlay();}
void CPlotter::setDataFromDisk(bool b) {m_dataFromDisk=b;}

void CPlotter::setTol(int n)                                 //setTol()
{
  m_tol=n;
  DrawOverlay();
}

int CPlotter::DF() {return m_DF;}                              // get DF

void CPlotter::mousePressEvent(QMouseEvent *event)       //mousePressEvent
{
  int h = (m_Size.height()-60)/2;
  int x=event->x();
  int y=event->y();
  if(y < h+30) {
//    setFQSO(x,false);                               // Wideband waterfall
  } else {
    m_DF=int(m_ZoomStartFreq + x*m_fSample/32768.0);  // Zoomed waterfall
    DrawOverlay();
    update();
  }
}

void CPlotter::mouseDoubleClickEvent(QMouseEvent *event)  //mouse2click
{
  int h = (m_Size.height()-60)/2;
  int x=event->x();
  int y=event->y();
  if(y < h+30) {
    m_DF=0;
//    setFQSO(x,false);
    emit freezeDecode1(2);                  //### ???
  } else {
    float f = m_ZoomStartFreq + x*m_fSample/32768.0;
    m_DF=int(f);
    emit freezeDecode1(1);
    DrawOverlay();
  }
}

int CPlotter::autoZero()                                        //autoZero()
{
  m_z1=0;
  m_z2=0;
  int sum1=0;
  for(int i=0; i<256; i++) {
    sum1 += m_hist1[i];
    if(sum1 > m_Size.width()/2) {
      m_z1=i;
      break;
    }
  }
  int sum2=0;
  for(int i=0; i<256; i++) {
    sum2 += m_hist2[i];
    if(sum2 > 16384) {
      m_z2=i;
      break;
    }
  }
  double gain = pow(10.0,0.05*(m_plotGain+7));
//  double dz1 = (m_z1-38)/(5.0*gain);
  double dz2 = (m_z2-28)/(5.0*gain);
  if(m_z2 < 255) m_plotZero = int(m_plotZero + dz2 + 0.5);
  return m_plotZero;
}

void CPlotter::setPalette(QString palette)                      //setPalette()
{
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
  }

  if(palette=="Blue") {
    FILE* fp=fopen("blue.dat","r");
    int n,r,g,b;
    float xr,xg,xb;
    for(int i=0; i<256; i++) {
      fscanf(fp,"%d%f%f%f",&n,&xr,&xg,&xb);
      r=255.0*xr + 0.5;
      g=255.0*xg + 0.5;
      b=255.0*xb + 0.5;
      m_ColorTbl[i].setRgb(r,g,b);
    }
  }

  if(palette=="AFMHot") {
    FILE* fp=fopen("afmhot.dat","r");
    int n,r,g,b;
    float xr,xg,xb;
    for(int i=0; i<256; i++) {
      fscanf(fp,"%d%f%f%f",&n,&xr,&xg,&xb);
      r=255.0*xr + 0.5;
      g=255.0*xg + 0.5;
      b=255.0*xb + 0.5;
      m_ColorTbl[i].setRgb(r,g,b);
    }
  }

}

void CPlotter::set2Dspec(bool b)
{
  m_2Dspec=b;
  m_paintAllZoom=!b;
  DrawOverlay();                         //Redraw scales and ticks
  update();                              //trigger a new paintEvent}
}
