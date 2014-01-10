#include "txtune.h"
#include "ui_txtune.h"
#include <QDebug>

extern double txPower;
extern double iqAmp;
extern double iqPhase;
extern bool bTune;

TxTune::TxTune(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::TxTune)
{
    ui->setupUi(this);
}

TxTune::~TxTune()
{
    delete ui;
}

void TxTune::on_pwrSlider_valueChanged(int n)
{
  txPower=0.01*n;
}

void TxTune::on_ampSlider_valueChanged(int n)
{
  iqAmp=1.0 + 0.001*n;
  ui->ampSpinBox->setValue(iqAmp);
}

void TxTune::on_phaSlider_valueChanged(int n)
{
  iqPhase=0.1*n;
  ui->phaSpinBox->setValue(iqPhase);
}

void TxTune::on_ampSpinBox_valueChanged(double d)
{
  iqAmp=d;
  int n=1000.0*(iqAmp-1.0);
  ui->ampSlider->setValue(n);
}

void TxTune::on_phaSpinBox_valueChanged(double d)
{
  iqPhase=d;
  int n=10.0*iqPhase;
  ui->phaSlider->setValue(n);
}

void TxTune::set_iqAmp(double d)
{
  ui->ampSpinBox->setValue(d);
}

void TxTune::set_iqPhase(double d)
{
  ui->phaSpinBox->setValue(d);
}

void TxTune::on_cbTxImage_toggled(bool b)
{
  ui->ampSlider->setEnabled(b);
  ui->ampSpinBox->setEnabled(b);
  ui->labAmp->setEnabled(b);
  ui->phaSlider->setEnabled(b);
  ui->phaSpinBox->setEnabled(b);
  ui->labPha->setEnabled(b);
}

void TxTune::on_pbTune_clicked()
{
  bTune = !bTune;
  if(bTune) {
    QString style="QPushButton{background-color: red;}";
    ui->pbTune->setStyleSheet(style);
  } else {
    ui->pbTune->setStyleSheet("");
  }
}
