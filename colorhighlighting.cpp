#include "colorhighlighting.h"
#include "ui_colorhighlighting.h"

#include <QDebug>

ColorHighlighting::ColorHighlighting(QWidget *parent) :
  QDialog(parent),
  ui(new Ui::ColorHighlighting)
{
  qDebug() << "AA";
  ui->setupUi(this);
  qDebug() << "BB";
}

ColorHighlighting::~ColorHighlighting()
{
  delete ui;
}
