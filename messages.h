#ifndef MESSAGES_H
#define MESSAGES_H

#include <QDialog>

namespace Ui {
  class Messages;
}

class Messages : public QDialog
{
  Q_OBJECT

public:
  explicit Messages(QWidget *parent = 0);
  void setText(QString t);
  void setColors(QString t);

    ~Messages();

signals:
  void click2OnCallsign(QString hiscall, QString t2);

private slots:
  void selectCallsign2(bool ctrl);
  void on_checkBox_stateChanged(int arg1);

private:
    Ui::Messages *ui;
    QString m_t;
    QString m_colorBackground;
    QString m_color0;
    QString m_color1;
    QString m_color2;
    QString m_color3;

    bool m_cqOnly;
};

#endif // MESSAGES_H
