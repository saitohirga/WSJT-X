//#include "commons.h"
#include <QSettings>
#include "echoplot.h"
#include "echograph.h"
#include "ui_echograph.h"

#define NSMAX2 1366

EchoGraph::EchoGraph(QSettings * settings, QWidget *parent) :
  QDialog(parent),
  m_settings (settings),
  ui(new Ui::EchoGraph)
{
  ui->setupUi(this);
  this->setWindowFlags(Qt::Dialog);
  this->installEventFilter(parent);                   //Installing the filter
  ui->echoPlot->setCursor(Qt::CrossCursor);
  this->setMaximumWidth(2048);
  this->setMaximumHeight(880);
  ui->echoPlot->setMaximumHeight(800);

//Restore user's settings
  m_settings->beginGroup("EchoGraph");
  restoreGeometry (m_settings->value ("geometry", saveGeometry ()).toByteArray ());
  ui->echoPlot->setPlotZero(m_settings->value("PlotZero", 0).toInt());
  ui->echoPlot->setPlotGain(m_settings->value("PlotGain", 0).toInt());
  ui->zeroSlider->setValue(ui->echoPlot->getPlotZero());
  ui->gainSlider->setValue(ui->echoPlot->getPlotGain());
  ui->smoothSpinBox->setValue(m_settings->value("Smooth",0).toInt());
  ui->echoPlot->m_blue=m_settings->value("BlueCurve",false).toBool();
  ui->cbBlue->setChecked(ui->echoPlot->m_blue);
  m_settings->endGroup();
}

EchoGraph::~EchoGraph()
{
  saveSettings();
  delete ui;
}

void EchoGraph::closeEvent (QCloseEvent * e)
{
  saveSettings ();
  QDialog::closeEvent (e);
}

void EchoGraph::saveSettings()
{
//Save user's settings
  m_settings->beginGroup("EchoGraph");
  m_settings->setValue ("geometry", saveGeometry ());
  m_settings->setValue("PlotZero",ui->echoPlot->m_plotZero);
  m_settings->setValue("PlotGain",ui->echoPlot->m_plotGain);
  m_settings->setValue("Smooth",ui->echoPlot->m_smooth);
  m_settings->setValue("BlueCurve",ui->echoPlot->m_blue);
  m_settings->endGroup();
}

void EchoGraph::plotSpec()
{
  ui->echoPlot->draw();
}

void EchoGraph::on_smoothSpinBox_valueChanged(int n)
{
  ui->echoPlot->setSmooth(n);
  ui->echoPlot->draw();
}

void EchoGraph::on_cbBlue_toggled(bool checked)
{
  ui->echoPlot->m_blue=checked;
  ui->echoPlot->draw();
}

void EchoGraph::on_gainSlider_valueChanged(int value)
{
  ui->echoPlot->setPlotGain(value);
  ui->echoPlot->draw();
}

void EchoGraph::on_zeroSlider_valueChanged(int value)
{
  ui->echoPlot->setPlotZero(value);
  ui->echoPlot->draw();
}
