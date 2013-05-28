#include "widegraph.h"
#include "ui_widegraph.h"
#include "commons.h"

WideGraph::WideGraph(QWidget *parent) :
  QDialog(parent),
  ui(new Ui::WideGraph)
{
  ui->setupUi(this);
  this->setWindowFlags(Qt::Dialog);
  this->installEventFilter(parent); //Installing the filter
  ui->widePlot->setCursor(Qt::CrossCursor);
  this->setMaximumWidth(2048);
  this->setMaximumHeight(880);
  ui->widePlot->setMaximumHeight(800);
  ui->widePlot->m_bCurrent=false;

  connect(ui->widePlot, SIGNAL(freezeDecode1(int)),this,
          SLOT(wideFreezeDecode(int)));

  m_fMin=1000;
  ui->fMinSpinBox->setValue(m_fMin);

  //Restore user's settings
  QString inifile(QApplication::applicationDirPath());
  inifile += "/wsjtx.ini";
  QSettings settings(inifile, QSettings::IniFormat);

  settings.beginGroup("WideGraph");
  ui->widePlot->setPlotZero(settings.value("PlotZero", 0).toInt());
  ui->widePlot->setPlotGain(settings.value("PlotGain", 0).toInt());
  ui->zeroSpinBox->setValue(ui->widePlot->getPlotZero());
  ui->gainSpinBox->setValue(ui->widePlot->getPlotGain());
  int n = settings.value("FreqSpan",2).toInt();
  int w = settings.value("PlotWidth",1000).toInt();
  ui->widePlot->m_w=w;
  ui->freqSpanSpinBox->setValue(n);
  ui->widePlot->setNSpan(n);
  m_waterfallAvg = settings.value("WaterfallAvg",5).toInt();
  ui->waterfallAvgSpinBox->setValue(m_waterfallAvg);
  ui->widePlot->m_bCurrent=settings.value("Current",false).toBool();
  ui->widePlot->m_bCumulative=settings.value("Cumulative",false).toBool();
  ui->widePlot->m_bJT9Sync=settings.value("JT9Sync",true).toBool();
  if(ui->widePlot->m_bCurrent) ui->spec2dComboBox->setCurrentIndex(0);
  if(ui->widePlot->m_bCumulative) ui->spec2dComboBox->setCurrentIndex(1);
  if(ui->widePlot->m_bJT9Sync) ui->spec2dComboBox->setCurrentIndex(2);
  int nbpp=settings.value("BinsPerPixel",2).toInt();
  ui->widePlot->setBinsPerPixel(nbpp);
  m_qsoFreq=settings.value("QSOfreq",1500).toInt();
  ui->widePlot->setFQSO(m_qsoFreq,true);
  settings.endGroup();
}

WideGraph::~WideGraph()
{
  saveSettings();
  delete ui;
}

void WideGraph::saveSettings()
{
  //Save user's settings
  QString inifile(QApplication::applicationDirPath());
  inifile += "/wsjtx.ini";
  QSettings settings(inifile, QSettings::IniFormat);

  settings.beginGroup("WideGraph");
  settings.setValue("PlotZero",ui->widePlot->m_plotZero);
  settings.setValue("PlotGain",ui->widePlot->m_plotGain);
  settings.setValue("PlotWidth",ui->widePlot->plotWidth());
  settings.setValue("FreqSpan",ui->freqSpanSpinBox->value());
  settings.setValue("WaterfallAvg",ui->waterfallAvgSpinBox->value());
  settings.setValue("Current",ui->widePlot->m_bCurrent);
  settings.setValue("Cumulative",ui->widePlot->m_bCumulative);
  settings.setValue("JT9Sync",ui->widePlot->m_bJT9Sync);
  settings.setValue("BinsPerPixel",ui->widePlot->binsPerPixel());
  settings.setValue("QSOfreq",ui->widePlot->fQSO());
  settings.endGroup();
}

void WideGraph::dataSink2(float s[], float red[], float df3, int ihsym,
                          int ndiskdata)
{
  static float splot[NSMAX];
  static float swide[2048];
  static float rwide[2048];
  int nbpp = ui->widePlot->binsPerPixel();
  static int n=0;

  //Average spectra over specified number, m_waterfallAvg
  if (n==0) {
    for (int i=0; i<NSMAX; i++)
      splot[i]=s[i];
  } else {
    for (int i=0; i<NSMAX; i++)
      splot[i] += s[i];
  }
  n++;

  if (n>=m_waterfallAvg) {
    for (int i=0; i<NSMAX; i++)
        splot[i] /= n;                       //Normalize the average
    n=0;

//    int w=ui->widePlot->plotWidth();
    int i0=-1;                            //###
    int i=i0;
    int jz=1000.0/df3;
    for (int j=0; j<jz; j++) {
      float sum=0;
      float rsum=0;
      for (int k=0; k<nbpp; k++) {
        i++;
        sum += splot[i];
        rsum += red[i];
      }
      swide[j]=sum;
      rwide[j]=rsum/nbpp;
//      if(lstrong[1 + i/32]!=0) swide[j]=-smax;   //Tag strong signals
    }

// Time according to this computer
    qint64 ms = QDateTime::currentMSecsSinceEpoch() % 86400000;
    int ntr = (ms/1000) % m_TRperiod;
    if((ndiskdata && ihsym <= m_waterfallAvg) || (!ndiskdata && ntr<m_ntr0)) {
      for (int i=0; i<2048; i++) {
        swide[i] = 1.e30;
      }
    }
    m_ntr0=ntr;
    ui->widePlot->draw(swide,rwide,i0);
  }
}

void WideGraph::on_freqSpanSpinBox_valueChanged(int n)
{
  ui->widePlot->setBinsPerPixel(n);
}

void WideGraph::on_waterfallAvgSpinBox_valueChanged(int n)
{
  m_waterfallAvg = n;
}

void WideGraph::on_zeroSpinBox_valueChanged(int value)
{
  ui->widePlot->setPlotZero(value);
}

void WideGraph::on_gainSpinBox_valueChanged(int value)
{
  ui->widePlot->setPlotGain(value);
}

void WideGraph::keyPressEvent(QKeyEvent *e)
{  
  switch(e->key())
  {
  int n;
  case Qt::Key_F11:
    n=11;
    if(e->modifiers() & Qt::ControlModifier) n+=100;
    emit f11f12(n);
    break;
  case Qt::Key_F12:
    n=12;
    if(e->modifiers() & Qt::ControlModifier) n+=100;
    emit f11f12(n);
    break;
  default:
    e->ignore();
  }
}

void WideGraph::setQSOfreq(int n)
{
  m_qsoFreq=n;
  ui->widePlot->setFQSO(m_qsoFreq,true);
  if(m_lockTxFreq) setTxFreq(m_qsoFreq);
}

int WideGraph::QSOfreq()
{
  return ui->widePlot->fQSO();
}

int WideGraph::nSpan()
{
  return ui->widePlot->m_nSpan;
}

float WideGraph::fSpan()
{
  return ui->widePlot->m_fSpan;
}

int WideGraph::nStartFreq()
{
  return ui->widePlot->startFreq();
}

void WideGraph::wideFreezeDecode(int n)
{
  emit freezeDecode2(n);
}

void WideGraph::setRxRange(int fMin, int fMax)
{
  ui->widePlot->setRxRange(fMin,fMax);
  ui->widePlot->DrawOverlay();
  ui->widePlot->update();
}

int WideGraph::getFmin()
{
  return m_fMin;
}

int WideGraph::getFmax()
{
  return m_fMax;
}

void WideGraph::setfMax(int n)
{
  m_fMax = n;
  setRxRange(m_fMin,m_fMax);
}

void WideGraph::setFcal(int n)
{
  m_fCal=n;
  ui->widePlot->setFcal(n);
}

void WideGraph::setPalette(QString palette)
{
  ui->widePlot->setPalette(palette);
}

double WideGraph::fGreen()
{
  return ui->widePlot->fGreen();
}

void WideGraph::setPeriod(int ntrperiod, int nsps)
{
  m_TRperiod=ntrperiod;
  m_nsps=nsps;
  ui->widePlot->setNsps(ntrperiod, nsps);
}

void WideGraph::setTxFreq(int n)
{
  ui->widePlot->setTxFreq(n);
}

void WideGraph::on_spec2dComboBox_currentIndexChanged(const QString &arg1)
{
  ui->widePlot->m_bCurrent=false;
  ui->widePlot->m_bCumulative=false;
  ui->widePlot->m_bJT9Sync=false;
  if(arg1=="Current") ui->widePlot->m_bCurrent=true;
  if(arg1=="Cumulative") ui->widePlot->m_bCumulative=true;
  if(arg1=="JT9 Sync") ui->widePlot->m_bJT9Sync=true;
}

void WideGraph::on_fMinSpinBox_valueChanged(int n)
{
  m_fMin=n;
  setRxRange(m_fMin,m_fMax);
}

void WideGraph::on_fMaxSpinBox_valueChanged(int n)
{
  m_fMax=n;
  setRxRange(m_fMin,m_fMax);
}

