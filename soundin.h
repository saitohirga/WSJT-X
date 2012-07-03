#ifndef SOUNDIN_H
#define SOUNDIN_H

#include <QtCore>
#include <QDebug>
#include <valarray>

#ifdef Q_OS_WIN32
#include <winsock.h>
#else
#include <sys/socket.h>
#endif //Q_OS_WIN32

// Thread gets audio data from soundcard and signals when a buffer of
// specified size is available.
class SoundInThread : public QThread
{
  Q_OBJECT
  bool quitExecution;           // if true, thread exits gracefully
  double m_rate;                // sample rate
  unsigned bufSize;             // user's buffer size

protected:
  virtual void run();

public:
  bool m_dataSinkBusy;

  SoundInThread():
    quitExecution(false),
    m_dataSinkBusy(false),
    m_rate(0),
    bufSize(0)
  {
  }

  void setInputDevice(qint32 n);
  void setMonitoring(bool b);
  int  mhsym();

signals:
  void bufferAvailable(std::valarray<qint16> samples, double rate);
  void readyForFFT(int k);
  void error(const QString& message);
  void status(const QString& message);

public slots:
  void quit();

private:

  double m_fAdd;
  bool   m_net;
  bool   m_monitoring;
  bool   m_bForceCenterFreq;
  bool   m_IQswap;
  bool   m_10db;
  double m_dForceCenterFreq;
  qint32 m_nrx;
  qint32 m_hsym;
  qint32 m_nDevIn;

};

extern "C" {
  void recvpkt_(int* nsam, quint16* iblk, qint8* nrx, int* k, double s1[],
                double s2[], double s3[]);
}

#endif // SOUNDIN_H
