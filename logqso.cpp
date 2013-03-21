#include "logqso.h"
#include "ui_logqso.h"
#include <QDebug>

LogQSO::LogQSO(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::LogQSO)
{
    ui->setupUi(this);
}

LogQSO::~LogQSO()
{
    delete ui;
}

void LogQSO::initLogQSO()
{
  qDebug() << "A";
}

void LogQSO::accept()
{
  qDebug() << "Z";
  QDialog::accept();
}
