// -*- Mode: C++ -*-
#ifndef ARRL_DIGI_H_
#define ARRL_DIGI_H_

#include <QWidget>

class QSettings;
class QFont;

namespace Ui {
  class ActiveStations;
}

class ActiveStations
  : public QWidget
{
  Q_OBJECT

public:
  explicit ActiveStations(QSettings *, QFont const&, QWidget * parent = 0);
  ~ActiveStations();
  void displayActiveStations(QString const&);
  void changeFont (QFont const&);

private:
  void read_settings ();
  void write_settings ();
  void setContentFont (QFont const&);
  QSettings * settings_;

  QScopedPointer<Ui::ActiveStations> ui;
};

#endif
