#ifndef SOUNDOUT_H
#define SOUNDOUT_H

#include <portaudio.h>

#include <QObject>
#include <QString>

extern "C" int d2aCallback(const void *, void *,
                           unsigned long,
                           PaStreamCallbackTimeInfo const *,
                           PaStreamCallbackFlags,
                           void *);

// An instance of this sends audio data to a specified soundcard.
// Output can be muted while underway, preserving waveform timing when
// transmission is resumed.

class SoundOutput : public QObject
{
  Q_OBJECT;

  Q_PROPERTY(bool running READ isRunning);
  Q_PROPERTY(bool mute READ isMuted WRITE mute);
  Q_PROPERTY(bool tune READ isTuning WRITE tune);

public:
  SoundOutput();
  ~SoundOutput();

  bool isRunning() const {return m_active;}
  bool isMuted() const {return m_callbackData.mute;}
  bool isTuning() const {return m_callbackData.tune;}
  double outputLatency() const {return m_outputLatency;}

  // the following can be called while the stream is running
  void setTxFreq(int n) {m_callbackData.ntxfreq = n;}
  void setXIT(int n) {m_callbackData.xit = n;}
  void mute(bool b = true) {m_callbackData.mute = b;}
  void tune(bool b = true) {m_callbackData.tune = b;}

public slots:
  void start(qint32 deviceNumber, QString const& mode,int TRPeriod,int nsps,int txFreq,int xit,double txsnrdb = 99.);
  void stop();

// Private members
private:
  PaStream * m_stream;
  PaTime m_outputLatency;

  struct CallbackData
  {
    //Parameters sent to or received from callback function
    double volatile txsnrdb;
    double volatile dnsps;	//Samples per symbol (at 12000 Hz)
    int volatile    ntrperiod;	//T/R period (s)
    int volatile    ntxfreq;
    int volatile    xit;
    int volatile    ncall;
    int volatile    nsym;
    bool volatile   mute;
    bool volatile   bRestart;
    bool volatile   tune;
  } m_callbackData;

  qint64  m_ms0;
  bool m_active;

  friend int d2aCallback(const void *, void *,
			 unsigned long,
			 PaStreamCallbackTimeInfo const *,
			 PaStreamCallbackFlags,
			 void *);
};

#endif
