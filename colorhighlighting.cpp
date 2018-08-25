#include "colorhighlighting.h"
#include "ui_colorhighlighting.h"

#include <QApplication>
#include <QDebug>

ColorHighlighting::ColorHighlighting(QWidget *parent) :
  QDialog(parent),
  ui(new Ui::ColorHighlighting)
{
  ui->setupUi(this);
}

ColorHighlighting::~ColorHighlighting()
{
  delete ui;
}

void ColorHighlighting::colorHighlightlingSetup()
{
  setWindowTitle(QApplication::applicationName() + " - Colors");
}
