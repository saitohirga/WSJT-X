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
  void displayRecentStations(QString const&);
  void changeFont (QFont const&);
  int  maxRecent();
  int  maxAge();
  void setClickOK(bool b);
  void erase();
  bool readyOnly();
  Q_SLOT void select();

  bool m_clickOK=false;

signals:
  void callSandP(int nline);

private:
  void read_settings ();
  void write_settings ();

  qint64 m_msec0=0;
  QSettings * settings_;

  QScopedPointer<Ui::ActiveStations> ui;
};

#endif
