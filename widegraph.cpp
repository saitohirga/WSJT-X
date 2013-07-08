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

  connect(ui->widePlot, SIGNAL(setFreq1(int,int)),this,
          SLOT(setFreq2(int,int)));

  m_fMin=3000;
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
  ui->widePlot->m_bCumulative=settings.value("Cumulative",true).toBool();
  if(ui->widePlot->m_bCurrent) ui->spec2dComboBox->setCurrentIndex(0);
  if(ui->widePlot->m_bCumulative) ui->spec2dComboBox->setCurrentIndex(1);
  int nbpp=settings.value("BinsPerPixel",2).toInt();
  ui->widePlot->setBinsPerPixel(nbpp);
  m_slope=settings.value("Slope",0.0).toDouble();
  ui->slopeSpinBox->setValue(m_slope);
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
  settings.setValue("BinsPerPixel",ui->widePlot->binsPerPixel());
  settings.setValue("Slope",m_slope);
  settings.endGroup();
}

void WideGraph::dataSink2(float s[], float df3, int ihsym,
                          int ndiskdata)
{
  static float splot[NSMAX];
  static float swide[2048];
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
    int jz=5000.0/(nbpp*df3);
    for (int j=0; j<jz; j++) {
      float sum=0;
      for (int k=0; k<nbpp; k++) {
        i++;
        sum += splot[i];
      }
      swide[j]=sum;
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
    ui->widePlot->draw(swide,i0);
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

void WideGraph::setRxFreq(int n)
{
  m_rxFreq=n;
  ui->widePlot->setRxFreq(m_rxFreq,true);
  if(m_lockTxFreq) setTxFreq(m_rxFreq);
}

int WideGraph::rxFreq()
{
  return ui->widePlot->rxFreq();
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

void WideGraph::setRxRange(int fMin)
{
  ui->widePlot->setRxRange(fMin);
  ui->widePlot->DrawOverlay();
  ui->widePlot->update();
}

int WideGraph::getFmin()
{
  return m_fMin;
}

int WideGraph::getFmax()
{
  int n=ui->widePlot->getFmax();
  if(n>5000) n=5000;
  return n;
}

void WideGraph::setFmin(int n)
{
  m_fMin = n;
  ui->fMinSpinBox->setValue(n);
  setRxRange(m_fMin);
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
  emit setXIT2(n);
  ui->widePlot->setTxFreq(n);
}

void WideGraph::setMode(QString mode)
{
  m_mode=mode;
  ui->fMinSpinBox->setEnabled(m_mode=="JT9+JT65");
  ui->widePlot->setMode(mode);
  ui->widePlot->DrawOverlay();
  ui->widePlot->update();
}

void WideGraph::setModeTx(QString modeTx)
{
  m_modeTx=modeTx;
  ui->widePlot->setModeTx(modeTx);
  ui->widePlot->DrawOverlay();
  ui->widePlot->update();
}

void WideGraph::on_spec2dComboBox_currentIndexChanged(const QString &arg1)
{
  ui->widePlot->m_bCurrent=false;
  ui->widePlot->m_bCumulative=false;
  if(arg1=="Current") ui->widePlot->m_bCurrent=true;
  if(arg1=="Cumulative") ui->widePlot->m_bCumulative=true;
}

void WideGraph::on_fMinSpinBox_valueChanged(int n)
{
  m_fMin=n;
  setRxRange(m_fMin);
}

void WideGraph::on_slopeSpinBox_valueChanged(double d)
{
  m_slope=d;
}

void WideGraph::setSlope(double d)
{
  m_slope=d;
  ui->slopeSpinBox->setValue(d);
}

void WideGraph::setLockTxFreq(bool b)
{
  m_lockTxFreq=b;
  ui->widePlot->m_lockTxFreq=b;
}
double WideGraph::getSlope()
{
  return m_slope;
}

void WideGraph::setFreq2(int rxFreq, int txFreq)
{
  m_rxFreq=rxFreq;
  m_txFreq=txFreq;
  emit setFreq3(rxFreq,txFreq);
}
