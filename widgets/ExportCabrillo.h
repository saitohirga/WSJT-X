#ifndef EXPORTCABRILLO_H
#define EXPORTCABRILLO_H

#include <QDialog>
#include <QSettings>

namespace Ui {
class ExportCabrillo;
}

class ExportCabrillo : public QDialog
{
  Q_OBJECT

public:
  explicit ExportCabrillo(QSettings *settings, QWidget *parent = 0);
  void setFile(QString t);
  ~ExportCabrillo();

public slots:
  void accept();

protected:
  void closeEvent (QCloseEvent *) override;

private slots:
  void on_pbSaveAs_clicked();

private:
  QSettings * settings_;
  QString m_CabLog;
  void read_settings();
  void write_settings();
  Ui::ExportCabrillo *ui;
};

#endif // EXPORTCABRILLO_H
