#ifndef TXTUNE_H
#define TXTUNE_H

#include <QDialog>

namespace Ui {
class TxTune;
}

class TxTune : public QDialog
{
    Q_OBJECT
    
public:
    explicit TxTune(QWidget *parent = 0);
    ~TxTune();
    
private slots:
  void on_pwrSlider_valueChanged(int n);
  void on_ampSlider_valueChanged(int n);
  void on_phaSlider_valueChanged(int n);

private:
    Ui::TxTune *ui;
};

#endif // TXTUNE_H
