// -*- Mode: C++ -*-
#ifndef LogQSO_H
#define LogQSO_H

#ifdef QT5
#include <QtWidgets>
#else
#include <QtGui>
#endif

#include <QScopedPointer>

#include "Radio.hpp"

namespace Ui {
  class LogQSO;
}

class QSettings;

class LogQSO : public QDialog
{
  Q_OBJECT

public:
  explicit LogQSO(QString const& programTitle, QSettings *, QWidget *parent = 0);
  ~LogQSO();
  void initLogQSO(QString const& hisCall, QString const& hisGrid, QString mode,
                  QString const& rptSent, QString const& rptRcvd, QDateTime const& dateTimeOn,
                  QDateTime const& dateTimeOff,
                  Radio::Frequency dialFreq, QString const& myCall, QString const& myGrid,
                  bool noSuffix, bool toRTTY, bool dBtoComments);

public slots:
  void accept();

signals:
  void acceptQSO (QDateTime const& QSO_date_off, QString const& call, QString const& grid
                  , Radio::Frequency dial_freq, QString const& mode
                  , QString const& rpt_sent, QString const& rpt_received
                  , QString const& tx_power, QString const& comments
                  , QString const& name, QDateTime const& QSO_date_on);

protected:
  void hideEvent (QHideEvent *);

private:
  void loadSettings ();
  void storeSettings () const;

  QScopedPointer<Ui::LogQSO> ui;
  QSettings * m_settings;
  QString m_txPower;
  QString m_comments;
  Radio::Frequency m_dialFreq;
  QString m_myCall;
  QString m_myGrid;
  QDateTime m_dateTimeOn;
  QDateTime m_dateTimeOff;
};

#endif // LogQSO_H
