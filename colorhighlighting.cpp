#include "colorhighlighting.h"
#include "ui_colorhighlighting.h"
#include "SettingsGroup.hpp"

#include <QApplication>
#include <QDebug>

ColorHighlighting::ColorHighlighting(QSettings *settings, QWidget *parent) :
  QDialog(parent),
  settings_ {settings},
  ui(new Ui::ColorHighlighting)
{
  ui->setupUi(this);
  read_settings ();
}

ColorHighlighting::~ColorHighlighting()
{
  if (isVisible ()) write_settings ();
  delete ui;
}

void ColorHighlighting::read_settings ()
{
  SettingsGroup group {settings_, "ColorScheme"};
  restoreGeometry (settings_->value ("window/geometry").toByteArray ());
}

void ColorHighlighting::write_settings ()
{
  SettingsGroup group {settings_, "ColorScheme"};
  settings_->setValue ("window/geometry", saveGeometry ());
}


void ColorHighlighting::colorHighlightlingSetup(QColor color_CQ,QColor color_MyCall,
     QColor color_DXCC,QColor color_DXCCband,QColor color_NewCall,
     QColor color_NewCallBand,QColor color_NewGrid,QColor color_NewGridBand,
     QColor color_TxMsg,QColor color_LoTW)
{
  setWindowTitle(QApplication::applicationName() + " - Colors");
  ui->label->setStyleSheet(QString("background: %1").arg(color_CQ.name()));
  ui->label_3->setStyleSheet(QString("background: %1").arg(color_MyCall.name()));
  ui->label_5->setStyleSheet(QString("background: %1").arg(color_TxMsg.name()));
  ui->label_7->setStyleSheet(QString("background: %1").arg(color_DXCC.name()));
  ui->label_9->setStyleSheet(QString("background: %1").arg(color_DXCCband.name()));
  ui->label_11->setStyleSheet(QString("background: %1").arg(color_NewCall.name()));
  ui->label_13->setStyleSheet(QString("background: %1").arg(color_NewCallBand.name()));
  ui->label_15->setStyleSheet(QString("background: %1").arg(color_NewGrid.name()));
  ui->label_17->setStyleSheet(QString("background: %1").arg(color_NewGridBand.name()));
  ui->label_19->setStyleSheet(QString("color: %1").arg(color_LoTW.name()));
}
