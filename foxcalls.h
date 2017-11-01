#ifndef FOXCALLS_H
#define FOXCALLS_H

#include <QWidget>
#include <QScopedPointer>
#include <QFont>
#include <QDebug>

namespace Ui {
class FoxCalls;
}

class QSettings;
class QFont;

class FoxCalls : public QWidget
{
  Q_OBJECT

protected:
  void closeEvent (QCloseEvent *) override;

public:
  explicit FoxCalls(QSettings *, QWidget *parent = 0);
  ~FoxCalls();

  void saveSettings();
  void insertText(QString t);

private slots:
  void on_rbCall_toggled(bool b);
  void on_rbGrid_toggled(bool b);
  void on_rbSNR_toggled(bool b);
  void on_rbAge_toggled(bool b);
  void on_cbReverse_toggled(bool b);

private:
  bool m_bFirst=true;
  bool m_bReverse;
  QString m_t0;
  QSettings * m_settings;
  QScopedPointer<Ui::FoxCalls> ui;
};

#endif // FOXCALLS_H
