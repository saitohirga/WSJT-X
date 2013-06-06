#ifndef LogQSO_H
#define LogQSO_H

#ifdef QT5
#include <QtWidgets>
#else
#include <QtGui>
#endif

namespace Ui {
class LogQSO;
}

class LogQSO : public QDialog
{
  Q_OBJECT

public:
  explicit LogQSO(QWidget *parent = 0);
  ~LogQSO();
  void initLogQSO(QString hisCall, QString hisGrid, QString mode,
                  QString rptSent, QString rptRcvd, QDateTime dateTime,
                  double dialFreq, QString myCall, QString myGrid,
                  bool noSuffix, bool toRTTY, bool dBtoComments);

  double m_dialFreq;

  bool m_saveTxPower;
  bool m_saveComments;

  QString m_myCall;
  QString m_myGrid;
  QString m_txPower;
  QString m_comments;

  QDateTime m_dateTime;

public slots:
  void accept();
  void reject();

signals:
  void acceptQSO(bool accepted);

private slots:
  void on_cbTxPower_toggled(bool checked);
  void on_cbComments_toggled(bool checked);

private:
  Ui::LogQSO *ui;
};

#endif // LogQSO_H
