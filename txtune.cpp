#include "txtune.h"
#include "ui_txtune.h"
#include <QDebug>

extern double txPower;
extern double iqAmp;
extern double iqPhase;

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
}

void TxTune::on_phaSlider_valueChanged(int n)
{
  iqPhase=0.1*n;
}
