#ifndef FOXCALLS_H
#define FOXCALLS_H

#include <QWidget>
#include <QScopedPointer>

namespace Ui {
class FoxCalls;
}

class QSettings;

class FoxCalls : public QWidget
{
  Q_OBJECT

protected:
  void closeEvent (QCloseEvent *) override;

public:
  explicit FoxCalls(QSettings *, QWidget *parent = 0);
  ~FoxCalls();

  void   saveSettings();

private slots:
//  void on_binsPerPixelSpinBox_valueChanged(int n);

private:
  QSettings * m_settings;
  QScopedPointer<Ui::FoxCalls> ui;
};

#endif // FOXCALLS_H
