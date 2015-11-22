#include "widegraph.h"
#include <QApplication>
#include <QSettings>
#include "ui_widegraph.h"
#include "commons.h"
#include "Configuration.hpp"
#include "moc_widegraph.cpp"

static float swide[MAX_SCREENSIZE];

namespace
{
  auto user_defined = QObject::tr ("User Defined");
}

WideGraph::WideGraph(QSettings * settings, QWidget *parent) :
  QDialog(parent),
  ui(new Ui::WideGraph),
  m_settings (settings),
  m_palettes_path {":/Palettes"}
{
  ui->setupUi(this);

  setWindowTitle (QApplication::applicationName () + " - " + tr ("Wide Graph"));
  setWindowFlags (Qt::WindowCloseButtonHint | Qt::WindowMinimizeButtonHint);
  setMaximumWidth (MAX_SCREENSIZE);
  setMaximumHeight (880);

  ui->widePlot->setCursor(Qt::CrossCursor);
  ui->widePlot->setMaximumHeight(800);
  ui->widePlot->setCurrent(false);

  connect(ui->widePlot, SIGNAL(freezeDecode1(int)),this,
          SLOT(wideFreezeDecode(int)));

  connect(ui->widePlot, SIGNAL(setFreq1(int,int)),this,
          SLOT(setFreq2(int,int)));

  //Restore user's settings
  m_settings->beginGroup("WideGraph");
  restoreGeometry (m_settings->value ("geometry", saveGeometry ()).toByteArray ());
  ui->widePlot->setPlotZero(m_settings->value("PlotZero", 0).toInt());
  ui->widePlot->setPlotGain(m_settings->value("PlotGain", 0).toInt());
  ui->widePlot->setPlot2dGain(m_settings->value("Plot2dGain", 0).toInt());
  ui->widePlot->setPlot2dZero(m_settings->value("Plot2dZero", 0).toInt());
  ui->zeroSlider->setValue(ui->widePlot->plotZero());
  ui->gainSlider->setValue(ui->widePlot->plotGain());
  ui->gain2dSlider->setValue(ui->widePlot->plot2dGain());
  ui->zero2dSlider->setValue(ui->widePlot->plot2dZero());
  int n = m_settings->value("BinsPerPixel",2).toInt();
  m_bFlatten=m_settings->value("Flatten",true).toBool();
  ui->cbFlatten->setChecked(m_bFlatten);
  ui->widePlot->setFlatten(m_bFlatten);
  ui->widePlot->setBreadth(m_settings->value("PlotWidth",1000).toInt());
  ui->bppSpinBox->setValue(n);
  m_nsmo=m_settings->value("SmoothYellow",1).toInt();
  ui->smoSpinBox->setValue(m_nsmo);
  m_Percent2DScreen=m_settings->value("Percent2D",30).toInt();
  ui->sbPercent2dPlot->setValue(m_Percent2DScreen);
  m_waterfallAvg = m_settings->value("WaterfallAvg",5).toInt();
  ui->waterfallAvgSpinBox->setValue(m_waterfallAvg);
  ui->widePlot->setWaterfallAvg(m_waterfallAvg);
  ui->widePlot->setCurrent(m_settings->value("Current",false).toBool());
  ui->widePlot->setCumulative(m_settings->value("Cumulative",true).toBool());
  ui->widePlot->setLinearAvg(m_settings->value("LinearAvg",false).toBool());
  ui->widePlot->setReference(m_settings->value("Reference",false).toBool());
  if(ui->widePlot->current()) ui->spec2dComboBox->setCurrentIndex(0);
  if(ui->widePlot->cumulative()) ui->spec2dComboBox->setCurrentIndex(1);
  if(ui->widePlot->linearAvg()) ui->spec2dComboBox->setCurrentIndex(2);
  if(ui->widePlot->Reference()) ui->spec2dComboBox->setCurrentIndex(3);
  int nbpp=m_settings->value("BinsPerPixel",2).toInt();
  ui->widePlot->setBinsPerPixel(nbpp);
  ui->widePlot->setStartFreq(m_settings->value("StartFreq",0).toInt());
  ui->fStartSpinBox->setValue(ui->widePlot->startFreq());
  m_waterfallPalette=m_settings->value("WaterfallPalette","Default").toString();
  m_userPalette = WFPalette {m_settings->value("UserPalette").value<WFPalette::Colours> ()};
  int m_fMin = m_settings->value ("fMin", 2500).toInt ();
  ui->fSplitSpinBox->setValue (m_fMin);
  setRxRange (m_fMin);
  m_settings->endGroup();

  saveSettings ();		// update config with defaults

  QStringList allFiles = m_palettes_path.entryList(QDir::NoDotAndDotDot |
        QDir::System | QDir::Hidden | QDir::AllDirs | QDir::Files,
        QDir::DirsFirst);
  int index=0;
  foreach(QString file, allFiles) {
    QString t=file.mid(0,file.length()-4);
    ui->paletteComboBox->addItem(t);
    if(t==m_waterfallPalette) ui->paletteComboBox->setCurrentIndex(index);
    index++;
  }
  ui->paletteComboBox->addItem (user_defined);
  if (user_defined == m_waterfallPalette) ui->paletteComboBox->setCurrentIndex(index);
  readPalette ();
  m_bHaveTransmitted=false;
}

WideGraph::~WideGraph ()
{
}

void WideGraph::closeEvent (QCloseEvent * e)
{
  saveSettings ();
  QDialog::closeEvent (e);
}

void WideGraph::saveSettings()                                           //saveSettings
{
  m_settings->beginGroup ("WideGraph");
  m_settings->setValue ("geometry", saveGeometry ());
  m_settings->setValue ("PlotZero", ui->widePlot->plotZero());
  m_settings->setValue ("PlotGain", ui->widePlot->plotGain());
  m_settings->setValue ("Plot2dGain", ui->widePlot->plot2dGain());
  m_settings->setValue ("Plot2dZero", ui->widePlot->plot2dZero());
  m_settings->setValue ("PlotWidth", ui->widePlot->plotWidth ());
  m_settings->setValue ("BinsPerPixel", ui->bppSpinBox->value ());
  m_settings->setValue ("SmoothYellow", ui->smoSpinBox->value ());
  m_settings->setValue ("Percent2D",m_Percent2DScreen);
  m_settings->setValue ("WaterfallAvg", ui->waterfallAvgSpinBox->value ());
  m_settings->setValue ("Current", ui->widePlot->current());
  m_settings->setValue ("Cumulative", ui->widePlot->cumulative());
  m_settings->setValue ("LinearAvg", ui->widePlot->linearAvg());
  m_settings->setValue ("Reference", ui->widePlot->Reference());
  m_settings->setValue ("BinsPerPixel", ui->widePlot->binsPerPixel ());
  m_settings->setValue ("StartFreq", ui->widePlot->startFreq ());
  m_settings->setValue ("WaterfallPalette", m_waterfallPalette);
  m_settings->setValue ("UserPalette", QVariant::fromValue (m_userPalette.colours ()));
  m_settings->setValue ("Fmin", m_fMin);
  m_settings->setValue("Flatten",m_bFlatten);
  m_settings->endGroup ();
}

void WideGraph::dataSink2(float s[], float df3, int ihsym, int ndiskdata)  //dataSink2
{
  static float splot[NSMAX];
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
      float flagValue=1.0e30;
      if(m_bHaveTransmitted) flagValue=2.0e30;
      for (int i=0; i<2048; i++) {
        swide[i] = flagValue;
      }
      m_bHaveTransmitted=false;
    }
    m_ntr0=ntr;
    ui->widePlot->draw(swide,true);
  }
}

void WideGraph::on_bppSpinBox_valueChanged(int n)                            //bpp
{
  ui->widePlot->setBinsPerPixel(n);
}

void WideGraph::on_waterfallAvgSpinBox_valueChanged(int n)                  //Navg
{
  m_waterfallAvg = n;
  ui->widePlot->setWaterfallAvg(n);
}

void WideGraph::keyPressEvent(QKeyEvent *e)                                 //F11, F12
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
    QDialog::keyPressEvent (e);
  }
}

void WideGraph::setRxFreq(int n)                                           //setRxFreq
{
  ui->widePlot->setRxFreq(n);
  ui->widePlot->draw(swide,false);
  if(m_lockTxFreq) setTxFreq(n);
}

int WideGraph::rxFreq()                                                   //rxFreq
{
  return ui->widePlot->rxFreq();
}

int WideGraph::nStartFreq()                                             //nStartFreq
{
  return ui->widePlot->startFreq();
}

void WideGraph::wideFreezeDecode(int n)                              //wideFreezeDecode
{
  emit freezeDecode2(n);
}

void WideGraph::setRxRange(int fMin)                                //setRxRange
{
  ui->widePlot->setRxRange(fMin);
  ui->widePlot->DrawOverlay();
  ui->widePlot->update();
}

int WideGraph::Fmin()                                              //Fmin
{
  return m_fMin;
}

int WideGraph::Fmax()                                              //Fmax
{
  int n=ui->widePlot->Fmax();
  if(n>5000) n=5000;
  return n;
}

void WideGraph::setPeriod(int ntrperiod, int nsps)                  //SetPeriod
{
  m_TRperiod=ntrperiod;
  m_nsps=nsps;
  ui->widePlot->setNsps(ntrperiod, nsps);
}

void WideGraph::setTxFreq(int n)                                   //setTxFreq
{
  emit setXIT2(n);
  ui->widePlot->setTxFreq(n);
}

void WideGraph::setMode(QString mode)                              //setMode
{
  m_mode=mode;
  ui->fSplitSpinBox->setEnabled(m_mode=="JT9+JT65");
  ui->widePlot->setMode(mode);
  ui->widePlot->DrawOverlay();
  ui->widePlot->update();
}

void WideGraph::setSubMode(int n)                                  //setSubMode
{
  m_nSubMode=n;
  ui->widePlot->setSubMode(n);
  ui->widePlot->DrawOverlay();
  ui->widePlot->update();
}
void WideGraph::setModeTx(QString modeTx)                          //setModeTx
{
  m_modeTx=modeTx;
  ui->widePlot->setModeTx(modeTx);
  ui->widePlot->DrawOverlay();
  ui->widePlot->update();
}

                                                        //Current-Cumulative-Yellow
void WideGraph::on_spec2dComboBox_currentIndexChanged(const QString &arg1)
{
  ui->widePlot->setCurrent(false);
  ui->widePlot->setCumulative(false);
  ui->widePlot->setLinearAvg(false);
  ui->widePlot->setReference(false);
  ui->smoSpinBox->setEnabled(false);
  if(arg1=="Current") ui->widePlot->setCurrent(true);
  if(arg1=="Cumulative") ui->widePlot->setCumulative(true);
  if(arg1=="Linear Avg") {
    ui->widePlot->setLinearAvg(true);
    ui->smoSpinBox->setEnabled(true);
  }
  if(arg1=="Reference") {
    ui->widePlot->setReference(true);
  }
  if(ui->widePlot->m_bScaleOK) ui->widePlot->draw(swide,false);
}

void WideGraph::on_fSplitSpinBox_valueChanged(int n)              //fSplit
{
  m_fMin=n;
  setRxRange(m_fMin);
}

void WideGraph::setLockTxFreq(bool b)                             //LockTxFreq
{
  m_lockTxFreq=b;
  ui->widePlot->setLockTxFreq(b);
}

void WideGraph::setFreq2(int rxFreq, int txFreq)                  //setFreq2
{
  emit setFreq3(rxFreq,txFreq);
}

void WideGraph::setDialFreq(double d)                             //setDialFreq
{
  ui->widePlot->setDialFreq(d);
}

void WideGraph::setRxBand(QString band)
{
  ui->widePlot->setRxBand(band);
}


void WideGraph::on_fStartSpinBox_valueChanged(int n)             //fStart
{
  ui->widePlot->setStartFreq(n);
}

void WideGraph::readPalette ()                                   //readPalette
{
  try
    {
      if (user_defined == m_waterfallPalette)
        {
          ui->widePlot->setColours (WFPalette {m_userPalette}.interpolate ());
        }
      else
        {
          ui->widePlot->setColours (WFPalette {m_palettes_path.absoluteFilePath (m_waterfallPalette + ".pal")}.interpolate());
        }
    }
  catch (std::exception const& e)
    {
      QMessageBox msgBox0;
      msgBox0.setText(e.what());
      msgBox0.exec();
    }
}

void WideGraph::on_paletteComboBox_activated (QString const& palette)    //palette selector
{
  m_waterfallPalette = palette;
  readPalette();
}

void WideGraph::on_cbFlatten_toggled(bool b)                          //Flatten On/Off
{
  m_bFlatten=b;
  ui->widePlot->setFlatten(m_bFlatten);
}

void WideGraph::on_adjust_palette_push_button_clicked (bool)   //Adjust Palette
{
  try
    {
      if (m_userPalette.design ())
        {
          m_waterfallPalette = user_defined;
          ui->paletteComboBox->setCurrentText (m_waterfallPalette);
          readPalette ();
        }
    }
  catch (std::exception const& e)
    {
      QMessageBox msgBox0;
      msgBox0.setText(e.what());
      msgBox0.exec();
    }
}

bool WideGraph::flatten()                                              //Flatten
{
  return m_bFlatten;
}

void WideGraph::on_gainSlider_valueChanged(int value)                 //Gain
{
  ui->widePlot->setPlotGain(value);
}

void WideGraph::on_zeroSlider_valueChanged(int value)                 //Zero
{
  ui->widePlot->setPlotZero(value);
}

void WideGraph::on_gain2dSlider_valueChanged(int value)               //Gain2
{
  ui->widePlot->setPlot2dGain(value);
  if(ui->widePlot->m_bScaleOK) ui->widePlot->draw(swide,false);
}

void WideGraph::on_zero2dSlider_valueChanged(int value)               //Zero2
{
  ui->widePlot->setPlot2dZero(value);
  if(ui->widePlot->m_bScaleOK) ui->widePlot->draw(swide,false);
}

void WideGraph::setTol(int n)                                         //setTol
{
  ui->widePlot->setTol(n);
  ui->widePlot->DrawOverlay();
  ui->widePlot->update();
}

void WideGraph::on_smoSpinBox_valueChanged(int n)
{
  m_nsmo=n;
}

int WideGraph::smoothYellow()
{
  return m_nsmo;
}

void WideGraph::setWSPRtransmitted()
{
  m_bHaveTransmitted=true;
}

void WideGraph::on_sbPercent2dPlot_valueChanged(int n)
{
  m_Percent2DScreen=n;
  ui->widePlot->SetPercent2DScreen(n);
}
