#ifndef LogQSO_H
#define LogQSO_H

#include <QDialog>

namespace Ui {
class LogQSO;
}

class LogQSO : public QDialog
{
  Q_OBJECT

public:
  explicit LogQSO(QWidget *parent = 0);
  ~LogQSO();
  void initLogQSO();

public slots:
  void accept();

private:
  Ui::LogQSO *ui;
};

#endif // LogQSO_H
