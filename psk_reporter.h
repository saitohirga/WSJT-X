#ifndef PSK_REPORTER_H
#define PSK_REPORTER_H

#include <QtCore>
#include <QUdpSocket>
#include <QHostInfo>

class PSK_Reporter : public QObject
{
    Q_OBJECT
public:
    explicit PSK_Reporter(QObject *parent = 0);
    void setLocalStation(QString call, QString grid, QString antenna, QString programInfo);
    void addRemoteStation(QString call, QString grid, QString freq, QString mode, QString snr, QString time);
    
signals:
    
public slots:
    void sendReport();

private:
    QString m_header_h;
    QString m_rxInfoDescriptor_h;
    QString m_txInfoDescriptor_h;
    QString m_randomId_h;
    QString m_linkId_h;

    QString m_rxCall;
    QString m_rxGrid;
    QString m_rxAnt;
    QString m_progId;

    QQueue< QHash<QString,QString> > m_spotQueue;

    QUdpSocket *m_udpSocket;

    QTimer *reportTimer;

    int m_sequenceNumber;
};

#endif // PSK_REPORTER_H
