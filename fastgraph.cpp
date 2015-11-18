#include "fastgraph.h"
#include "commons.h"
#include <QSettings>
#include <QApplication>
#include "fastplot.h"
#include "ui_fastgraph.h"
#include "moc_fastgraph.cpp"

#define NSMAX2 1366

FastGraph::FastGraph(QSettings * settings, QWidget *parent) :
  QDialog {parent, Qt::Window | Qt::WindowTitleHint |
           Qt::WindowCloseButtonHint |
           Qt::WindowMinimizeButtonHint},
  m_settings (settings),
  ui(new Ui::FastGraph)
{
  ui->setupUi(this);
  setWindowTitle (QApplication::applicationName () + " - " + tr ("Fast Graph"));
  installEventFilter(parent);                   //Installing the filter
  ui->fastPlot->setCursor(Qt::CrossCursor);
  m_ave=40;

//Restore user's settings
  m_settings->beginGroup("FastGraph");
  restoreGeometry (m_settings->value ("geometry", saveGeometry ()).toByteArray ());
  ui->fastPlot->setPlotZero(m_settings->value("PlotZero", 0).toInt());
  ui->fastPlot->setPlotGain(m_settings->value("PlotGain", 0).toInt());
  ui->zeroSlider->setValue(ui->fastPlot->m_plotZero);
  ui->gainSlider->setValue(ui->fastPlot->m_plotGain);
  ui->fastPlot->setGreenZero(m_settings->value("GreenZero", 0).toInt());
  ui->greenZeroSlider->setValue(ui->fastPlot->m_greenZero);
  m_settings->endGroup();

  connect(ui->fastPlot, SIGNAL(fastPick1(int,int,int)),this,
          SLOT(fastPick1a(int,int,int)));
}

FastGraph::~FastGraph()
{
  saveSettings();
  delete ui;
}

void FastGraph::closeEvent (QCloseEvent * e)
{
  saveSettings ();
  QDialog::closeEvent (e);
}

void FastGraph::saveSettings()
{
//Save user's settings
  m_settings->beginGroup("FastGraph");
  m_settings->setValue ("geometry", saveGeometry ());
  m_settings->setValue("PlotZero",ui->fastPlot->m_plotZero);
  m_settings->setValue("PlotGain",ui->fastPlot->m_plotGain);
  m_settings->setValue("GreenZero",ui->fastPlot->m_greenZero);
  m_settings->setValue("GreenGain",ui->fastPlot->m_greenGain);
  m_settings->endGroup();
}

void FastGraph::plotSpec()
{
  ui->fastPlot->draw();
}

void FastGraph::on_gainSlider_valueChanged(int value)
{
  ui->fastPlot->setPlotGain(value);
  ui->fastPlot->draw();
//  qDebug() << "B" << ui->gainSlider->value() << ui->zeroSlider->value()
//           << ui->greenZeroSlider->value()  << m_ave;
}

void FastGraph::on_zeroSlider_valueChanged(int value)
{
  ui->fastPlot->setPlotZero(value);
  ui->fastPlot->draw();
}

void FastGraph::on_greenZeroSlider_valueChanged(int value)
{
  ui->fastPlot->setGreenZero(value);
  ui->fastPlot->draw();
}

void FastGraph::fastPick1a(int x0, int x1, int y)
{
  Q_EMIT fastPick(x0,x1,y);
}

void FastGraph::on_pbAutoLevel_clicked()
{
  float sum=0.0;
  for(int i=0; i<=fast_jh; i++) {
    sum += fast_green[i];
  }
  m_ave=sum/fast_jh;
  ui->gainSlider->setValue(127-int(2.2*m_ave));
  ui->zeroSlider->setValue(int(m_ave)+20);
  ui->greenZeroSlider->setValue(160-int(3.3*m_ave));
//  qDebug() << "A" << ui->gainSlider->value() << ui->zeroSlider->value()
//           << ui->greenZeroSlider->value()  << m_ave;
}
