#ifndef WSPRNET_H
#define WSPRNET_H

#include <QObject>
#include <QtNetwork>

class WSPRNet : public QObject
{
Q_OBJECT
public:
    explicit WSPRNet(QObject *parent = 0);
    void upload(QString call, QString grid, QString rfreq, QString tfreq,
                QString mode, QString tpct, QString dbm, QString version,
                QString fileName);
    static bool decodeLine(QString line, QHash<QString,QString> &query);

signals:
    void uploadStatus(QString);

public slots:
    void networkReply(QNetworkReply *);
    void work();

private:
    QNetworkAccessManager *networkManager;
    QString wsprNetUrl;
    QString m_call, m_grid, m_rfreq, m_tfreq, m_mode, m_tpct, m_dbm, m_vers, m_file;
    QQueue<QString> urlQueue;
    QTimer *uploadTimer;
    int m_urlQueueSize;
    int m_uploadType;

    QString urlEncodeNoSpot();
    QString urlEncodeSpot(QHash<QString,QString> spot);
};

#endif // WSPRNET_H
