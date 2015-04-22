#ifndef MESSAGEAVERAGING_H
#define MESSAGEAVERAGING_H

#include <QWidget>
#include <QDebug>
#include <QCheckBox>
#include <QList>
#include <QLineEdit>

class QSettings;

namespace Ui {
class MessageAveraging;
}

class MessageAveraging : public QWidget
{
  Q_OBJECT

public:
  explicit MessageAveraging(QSettings * settings, QWidget *parent = 0);
  ~MessageAveraging();
  void displayAvg(QString t);

protected:
  void closeEvent (QCloseEvent *) override;

private:
  void read_settings ();
  void write_settings ();
  QSettings * settings_;

  qint32 m_k;

  Ui::MessageAveraging *ui;
};

#endif // MESSAGEAVERAGING_H
