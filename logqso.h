#ifndef LogQSO_H
#define LogQSO_H

#ifdef QT5
#include <QtWidgets>
#else
#include <QtGui>
#endif

#include <QScopedPointer>

namespace Ui {
  class LogQSO;
}

class QSettings;
class Configuration;

class LogQSO : public QDialog
{
  Q_OBJECT

public:
  explicit LogQSO(QString const& programTitle, QSettings *, Configuration const *, QWidget *parent = 0);
  ~LogQSO();
  void initLogQSO(QString hisCall, QString hisGrid, QString mode,
                  QString rptSent, QString rptRcvd, QDateTime dateTime,
                  double dialFreq, QString myCall, QString myGrid,
                  bool noSuffix, bool toRTTY, bool dBtoComments);

public slots:
  void accept();
  void reject();

signals:
  void acceptQSO(bool accepted);

protected:
  void hideEvent (QHideEvent *);

private:
  void loadSettings ();
  void storeSettings () const;

  QScopedPointer<Ui::LogQSO> ui;
  QSettings * m_settings;
  Configuration const * m_configuration;
  QString m_txPower;
  QString m_comments;
  double m_dialFreq;
  QString m_myCall;
  QString m_myGrid;
  QDateTime m_dateTime;
};

#endif // LogQSO_H
