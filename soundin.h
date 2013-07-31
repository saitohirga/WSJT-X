#ifndef QAUDIO_INPUT
#ifndef SOUNDIN_H
#define SOUNDIN_H

#include <portaudio.h>

#include <QtCore>
#include <QScopedPointer>
#include <QDebug>

extern "C" int a2dCallback( const void *, void *, unsigned long, PaStreamCallbackTimeInfo const *, PaStreamCallbackFlags, void *);

// Gets audio data from soundcard and signals when a buffer of
// specified size is available.
class SoundInput : public QObject
{
  Q_OBJECT

public:
  SoundInput();
  ~SoundInput();

  void setMonitoring(bool b);
  void setPeriod(int ntrperiod, int nsps) /* this can be called while processing samples */
  {
    m_TRperiod=ntrperiod;
    m_nsps=nsps;
  }
  int  mstep() const {return m_step;}
  double samFacIn() const {return m_SamFacIn;}

signals:
  void readyForFFT(int k);
  void error(const QString& message);
  void status(const QString& message);

public slots:
  void start(qint32 device);
  void intervalNotify();
  void stop();

private:
  PaStream * m_inStream;
  bool m_dataSinkBusy;
  double m_SamFacIn;                    //(Input sample rate)/12000.0
  qint32 m_step;
  qint32 m_TRperiod;
  qint32 m_TRperiod0;
  qint32 m_nsps;
  bool   m_monitoring;
  qint64 m_ms0;
  int m_ntr0;
  int m_nBusy;
  int m_nstep0;
  int m_nsps0;

  QTimer m_intervalTimer;

  struct CallbackData
  {
    int kin;          //Parameters sent to/from the portaudio callback function
    int ncall;
    bool bzero;
    bool monitoring;
  } m_callbackData;

  friend int a2dCallback(void const *, void *, unsigned long, PaStreamCallbackTimeInfo const *, PaStreamCallbackFlags, void *);
};
#endif // SOUNDIN_H

#else  // QAUDIO_INPUT
#ifndef SOUNDIN_H
#define SOUNDIN_H

#include <QtCore>
#include <QScopedPointer>
#include <QDebug>
#include <QAudioDeviceInfo>
#include <QAudioInput>

// Gets audio data from soundcard and signals when a buffer of
// specified size is available.
class SoundInput : public QObject
{
	Q_OBJECT

public:
	SoundInput();
	~SoundInput();

	void setMonitoring(bool b);
	void setPeriod(int ntrperiod, int nsps) /* this can be called while processing samples */
	{
		m_TRperiod=ntrperiod;
		m_nsps=nsps;
	}
	int  mstep() const {return m_step;}
	double samFacIn() const {return m_SamFacIn;}

signals:
	void readyForFFT(int k);
	void error(const QString& message);
	void status(const QString& message);

public slots:
	void start(qint32 device);
	void intervalNotify();
	void stop();

private:
	bool m_dataSinkBusy;
	double m_SamFacIn;                     //(Input sample rate)/12000.0
	qint32 m_step;
	qint32 m_TRperiod;
	qint32 m_TRperiod0;
	qint32 m_nsps;
	bool   m_monitoring;
	qint64 m_ms0;
	int m_ntr0;
	int m_nBusy;
	int m_nstep0;
	int m_nsps0;

	QTimer m_intervalTimer;
	QAudioDeviceInfo inputDevice;          // audioinput device name
	QAudioInput* audioInput;
	QIODevice* stream;

	struct CallbackData
	{
		int kin;
		int ncall;
		bool bzero;
		bool monitoring;
	} m_callbackData;  //Parameters sent to/from the Notify function
};
#endif // SOUNDIN_H
#endif // QAUDIO_INPUT
