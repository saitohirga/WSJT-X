#include "widegraph.h"
#include "ui_widegraph.h"

#define NFFT 32768

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

  connect(ui->widePlot, SIGNAL(freezeDecode1(int)),this,
          SLOT(wideFreezeDecode(int)));

  //Restore user's settings
  QString inifile(QApplication::applicationDirPath());
  inifile += "/map65.ini";
  QSettings settings(inifile, QSettings::IniFormat);

  settings.beginGroup("WideGraph");
  ui->widePlot->setPlotZero(settings.value("PlotZero", 20).toInt());
  ui->widePlot->setPlotGain(settings.value("PlotGain", 0).toInt());
  ui->zeroSpinBox->setValue(ui->widePlot->getPlotZero());
  ui->gainSpinBox->setValue(ui->widePlot->getPlotGain());
  int n = settings.value("FreqSpan",60).toInt();
  int w = settings.value("PlotWidth",1000).toInt();
  ui->freqSpanSpinBox->setValue(n);
  ui->widePlot->setNSpan(n);
  int nbpp = n * 32768.0/(w*96.0) + 0.5;
  ui->widePlot->setBinsPerPixel(nbpp);
  m_waterfallAvg = settings.value("WaterfallAvg",10).toInt();
  ui->waterfallAvgSpinBox->setValue(m_waterfallAvg);
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
  inifile += "/map65.ini";
  QSettings settings(inifile, QSettings::IniFormat);

  settings.beginGroup("WideGraph");
  settings.setValue("PlotZero",ui->widePlot->m_plotZero);
  settings.setValue("PlotGain",ui->widePlot->m_plotGain);
  settings.setValue("PlotWidth",ui->widePlot->plotWidth());
  settings.setValue("FreqSpan",ui->freqSpanSpinBox->value());
  settings.setValue("WaterfallAvg",ui->waterfallAvgSpinBox->value());
  settings.setValue("FreqOffset",ui->widePlot->freqOffset());
  settings.setValue("ForceCenterFreqBool",m_bForceCenterFreq);
  settings.setValue("ForceCenterFreqMHz",m_dForceCenterFreq);
  settings.endGroup();
}

void WideGraph::dataSink2(float s[], int nkhz, int ihsym, int ndiskdata,
                          uchar lstrong[])
{
  static float splot[NFFT];
  float swide[2048];
  float smax;
  double df;
  int nbpp = ui->widePlot->binsPerPixel();
  static int n=0;
  static int nkhz0=-999;
  static int n60z=0;

  df = m_fSample/32768.0;
  if(nkhz != nkhz0) {
    ui->widePlot->setNkhz(nkhz);                   //Why do we need both?
    ui->widePlot->SetCenterFreq(nkhz);             //Why do we need both?
    ui->widePlot->setFQSO(nkhz,true);
    nkhz0 = nkhz;
  }

  //Average spectra over specified number, m_waterfallAvg
  if (n==0) {
    for (int i=0; i<NFFT; i++)
      splot[i]=s[i];
  } else {
    for (int i=0; i<NFFT; i++)
      splot[i] += s[i];
  }
  n++;

  if (n>=m_waterfallAvg) {
    for (int i=0; i<NFFT; i++)
        splot[i] /= n;                       //Normalize the average
    n=0;

    int w=ui->widePlot->plotWidth();
    qint64 sf = nkhz + ui->widePlot->freqOffset() - 0.5*w*nbpp*df/1000.0;
    if(sf != ui->widePlot->startFreq()) ui->widePlot->SetStartFreq(sf);
    int i0=16384.0+(ui->widePlot->startFreq()-nkhz+1.27046+0.001*m_fCal) *
        1000.0/df + 0.5;
    int i=i0;
    for (int j=0; j<2048; j++) {
        smax=0;
        for (int k=0; k<nbpp; k++) {
            i++;
            if(splot[i]>smax) smax=splot[i];
        }
        swide[j]=smax;
        if(lstrong[1 + i/32]!=0) swide[j]=-smax;   //Tag strong signals
    }

// Time according to this computer
    qint64 ms = QDateTime::currentMSecsSinceEpoch() % 86400000;
    int n60 = (ms/1000) % 60;

    if((ndiskdata && ihsym <= m_waterfallAvg) || (!ndiskdata && n60<n60z)) {
      for (int i=0; i<2048; i++) {
        swide[i] = 1.e30;
      }
      for (int i=0; i<32768; i++) {
        splot[i] = 1.e30;
      }
    }
    n60z=n60;
    ui->widePlot->draw(swide,i0,splot);
  }
}

void WideGraph::on_freqSpanSpinBox_valueChanged(int n)
{
  ui->widePlot->setNSpan(n);
  int w = ui->widePlot->plotWidth();
  int nbpp = n * 32768.0/(w*96.0) + 0.5;
  if(nbpp < 1) nbpp=1;
  if(w > 0) {
    ui->widePlot->setBinsPerPixel(nbpp);
  }
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
  case Qt::Key_F11:
    emit f11f12(11);
    break;
  case Qt::Key_F12:
    emit f11f12(12);
    break;
  default:
    e->ignore();
  }
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

void WideGraph::setTol(int n)
{
  ui->widePlot->m_tol=n;
  ui->widePlot->DrawOverlay();
  ui->widePlot->update();
}

int WideGraph::Tol()
{
  return ui->widePlot->m_tol;
}

void WideGraph::setDF(int n)
{
  ui->widePlot->m_DF=n;
  ui->widePlot->DrawOverlay();
  ui->widePlot->update();
}

void WideGraph::setFcal(int n)
{
  m_fCal=n;
  ui->widePlot->setFcal(n);
}


int WideGraph::DF()
{
  return ui->widePlot->m_DF;
}

void WideGraph::on_autoZeroPushButton_clicked()
{
   int nzero=ui->widePlot->autoZero();
   ui->zeroSpinBox->setValue(nzero);
}

void WideGraph::setPalette(QString palette)
{
  ui->widePlot->setPalette(palette);
}

void WideGraph::on_cbSpec2d_toggled(bool b)
{
  ui->widePlot->set2Dspec(b);
}

double WideGraph::fGreen()
{
  return ui->widePlot->fGreen();
}
