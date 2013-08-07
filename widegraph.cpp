#include "widegraph.h"
#include "ui_widegraph.h"
#include "commons.h"

#define MAX_SCREENSIZE 2048

WideGraph::WideGraph(QWidget *parent) :
  QDialog(parent),
  ui(new Ui::WideGraph)
{
  ui->setupUi(this);
  this->setWindowFlags(Qt::Dialog);
  this->installEventFilter(parent); //Installing the filter
  ui->widePlot->setCursor(Qt::CrossCursor);
	this->setMaximumWidth(MAX_SCREENSIZE);
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
  ui->widePlot->setStartFreq(settings.value("StartFreq",0).toInt());
  ui->fStartSpinBox->setValue(ui->widePlot->startFreq());
  m_waterfallPalette=settings.value("WaterfallPalette","default").toString();
  ui->labPalette->setText(m_waterfallPalette.mid(0,1).toUpper() +
                          m_waterfallPalette.mid(1));
  settings.endGroup();
  readPalette("Palettes/" + m_waterfallPalette + ".pal");
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
  settings.setValue("StartFreq",ui->widePlot->startFreq());
  settings.setValue("WaterfallPalette",m_waterfallPalette);
  settings.endGroup();
}

void WideGraph::dataSink2(float s[], float df3, int ihsym,
                          int ndiskdata)
{
  static float splot[NSMAX];
	static float swide[MAX_SCREENSIZE];
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
    int i=int(ui->widePlot->startFreq()/df3 + 0.5);
    int jz=5000.0/(nbpp*df3);
		if(jz>MAX_SCREENSIZE) jz=MAX_SCREENSIZE;
    for (int j=0; j<jz; j++) {
      float sum=0;
      for (int k=0; k<nbpp; k++) {
        sum += splot[i++];
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
    ui->widePlot->draw(swide);
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

void WideGraph::setDialFreq(double d)
{
  m_dialFreq=d;
  ui->widePlot->setDialFreq(d);
}

void WideGraph::on_fStartSpinBox_valueChanged(int n)
{
  ui->widePlot->setStartFreq(n);
}

void WideGraph::on_pbPalette_clicked()
{
  QString fileName = QFileDialog::getOpenFileName(this, tr("Select Palette"),
      "./Palettes", tr("Files (*.pal)"));
  if(fileName!="") readPalette(fileName);
  /*
    QColor color = QColorDialog::getColor(Qt::yellow, this );
    if(color.isValid()) {
      qDebug( "ok" );
    }
  */
}

void WideGraph::readPalette(QString fileName)
{
  QFile f;
  f.setFileName(fileName);
  if(f.open(QIODevice::ReadOnly)) {
    QTextStream in(&f);
    int r[9],g[9],b[9];
    QString t;
    for(int i=0; i<9; i++) {
      t=in.readLine();
      r[i]=t.mid(0,3).toInt();
      g[i]=t.mid(4,3).toInt();
      b[i]=t.mid(8,3).toInt();
    }
    f.close();
    for(int i=0; i<256; i++) {
      int j0=i/32;
      int j1=j0+1;
      int k=i-32*j0;
      int rr=r[j0] + int((k*(r[j1]-r[j0]))/31 + 0.5);
      int gg=g[j0] + int((k*(g[j1]-g[j0]))/31 + 0.5);
      int bb=b[j0] + int((k*(b[j1]-b[j0]))/31 + 0.5);
      ui->widePlot->m_ColorTbl[i].setRgb(rr,gg,bb);
    }
    QFileInfo fileInfo(f);
    t=fileInfo.fileName();
    int n=t.length();
    m_waterfallPalette=t.mid(0,n-4);
    ui->labPalette->setText(m_waterfallPalette.mid(0,1).toUpper() +
                            m_waterfallPalette.mid(1));
  } else {
    QMessageBox msgBox0;
    QString t="Error: Cannot find requested palette file " + fileName;
    msgBox0.setText(t);
    msgBox0.exec();
  }
}
