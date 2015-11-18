#ifndef ECHOGRAPH_H
#define ECHOGRAPH_H
#include <QDialog>

namespace Ui {
  class EchoGraph;
}

class QSettings;

class EchoGraph : public QDialog
{
  Q_OBJECT

protected:
  void closeEvent (QCloseEvent *) override;

public:
  explicit EchoGraph(QSettings *, QWidget *parent = 0);
  ~EchoGraph();

  void   plotSpec();
  void   saveSettings();

private slots:
  void on_smoothSpinBox_valueChanged(int n);
  void on_cbBlue_toggled(bool checked);
  void on_gainSlider_valueChanged(int value);
  void on_zeroSlider_valueChanged(int value);  
  void on_binsPerPixelSpinBox_valueChanged(int n);

  void on_pbColors_clicked();

private:
  QSettings * m_settings;
  qint32 m_nColor;

  Ui::EchoGraph *ui;
};

#endif // ECHOGRAPH_H
