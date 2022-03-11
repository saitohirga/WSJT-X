// -*- Mode: C++ -*-
#ifndef ARRL_DIGI_H_
#define ARRL_DIGI_H_

#include <QWidget>

class QSettings;
class QFont;

namespace Ui {
  class ARRL_Digi;
}

class ARRL_Digi
  : public QWidget
{
  Q_OBJECT

public:
  explicit ARRL_Digi(QSettings *, QFont const&, QWidget * parent = 0);
  ~ARRL_Digi();
  void displayARRL_Digi(QString const&);
  void changeFont (QFont const&);

private:
  void read_settings ();
  void write_settings ();
  void setContentFont (QFont const&);
  QSettings * settings_;

  QScopedPointer<Ui::ARRL_Digi> ui;
};

#endif
