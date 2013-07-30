#include "soundin.h"
#include <stdexcept>

#define FRAMES_PER_BUFFER 1024
//#define NSMAX 1365
#define NSMAX 6827
#define NTMAX 120

extern "C" {
#include <portaudio.h>
extern struct {
  float ss[184*NSMAX];              //This is "common/jt9com/..." in fortran
  float savg[NSMAX];
//  float c0[2*NTMAX*1500];
  short int d2[NTMAX*12000];
  int nutc;                         //UTC as integer, HHMM
  int ndiskdat;                     //1 ==> data read from *.wav file
  int ntrperiod;                    //TR period (seconds)
  int mousefqso;                    //User-selected QSO freq (kHz)
  int newdat;                       //1 ==> new data, must do long FFT
  int npts8;                        //npts in c0() array
  int nfa;                          //Low decode limit (Hz)
  int nfb;                          //High decode limit (Hz)
  int ntol;                         //+/- decoding range around fQSO (Hz)
  int kin;
  int nzhsym;
  int nsave;
  int nagain;
  int ndepth;
  int ntxmode;
  int nmode;
  char datetime[20];
} jt9com_;
}

QString reportAudioError(QAudio::Error audioError)
{
	switch (audioError) {
	case QAudio::NoError: Q_ASSERT(false);
	case QAudio::OpenError: return QObject::tr(
					"An error opening the audio device has occurred.");
	case QAudio::IOError: return QObject::tr(
					"An error occurred during read/write of audio device.");
	case QAudio::UnderrunError: return QObject::tr(
					"Audio data not being fed to the audio device fast enough.");
	case QAudio::FatalError: return QObject::tr(
					"Non-recoverable error, audio device not usable at this time.");
	}
	Q_ASSERT(false);
	return "";
}

typedef struct
{
  int kin;          //Parameters sent to/from the portaudio callback function
  int ncall;
  bool bzero;
  bool monitoring;
} paUserData;


void SoundInThread::run()                           //SoundInThread::run()
{
  quitExecution = false;

//---------------------------------------------------- Soundcard Setup

	quitExecutionMutex.lock();
	quitExecution = false;
	quitExecutionMutex.unlock();

	//### Temporary: hardwired device selection
	QAudioDeviceInfo  DeviceInfo;
	QList<QAudioDeviceInfo> m_InDevices;
	QAudioDeviceInfo  m_InDeviceInfo;
	m_InDevices = DeviceInfo.availableDevices(QAudio::AudioInput);
	inputDevice = m_InDevices.at(0);
	//###

	const char* pcmCodec = "audio/pcm";
	QAudioFormat audioFormat = inputDevice.preferredFormat();
	audioFormat.setChannelCount(1);
	audioFormat.setCodec(pcmCodec);
	audioFormat.setSampleRate(12000);
	audioFormat.setSampleType(QAudioFormat::SignedInt);
	audioFormat.setSampleSize(16);

	if (!audioFormat.isValid()) {
		emit error(tr("Requested audio format is not available."));
		return;
	}

	QAudioInput audioInput(inputDevice, audioFormat);
	if (audioInput.error() != QAudio::NoError) {
		emit error(reportAudioError(audioInput.error()));
		return;
	}

	QIODevice* stream = audioInput.start();

  bool qe = quitExecution;
  static int ntr0=99;
  int k=0;
  int nsec;
  int ntr;
  int nBusy=0;
  int nstep0=0;
  int nsps0=0;
	qint16 buf0[4096];

//---------------------------------------------- Soundcard input loop
  while (!qe) {
		quitExecutionMutex.lock();
		qe = quitExecution;
		quitExecutionMutex.unlock();
    if (qe) break;

		// Error checking...
		if (audioInput.error() != QAudio::NoError) {
			emit error(reportAudioError(audioInput.error()));
			return;
		}

//  udata.monitoring=m_monitoring;
    qint64 ms = QDateTime::currentMSecsSinceEpoch();
    ms=ms % 86400000;
    nsec = ms/1000;             // Time according to this computer
    ntr = nsec % m_TRperiod;

// Reset buffer pointer and symbol number at start of minute
    if(ntr < ntr0 or !m_monitoring or m_nsps!=nsps0) {
      nstep0=0;
      nsps0=m_nsps;
//    udata.bzero=true;
			k=0;
    }
//  k=udata.kin;

		// How many new samples have been acquired?
		const qint32 bytesReady = audioInput.bytesReady();
		Q_ASSERT(bytesReady >= 0);
		Q_ASSERT(bytesReady % 2 == 0);
		if (bytesReady == 0) {
			msleep(50);
			continue;
		}

		// Get the new samples
		qint32 bytesRead;
		bytesRead = stream->read((char*)buf0, bytesReady);
		Q_ASSERT(bytesRead <= bytesReady);
		if (bytesRead < 0) {
			emit error(tr("audio stream QIODevice::read returned -1."));
			return;
		}
		Q_ASSERT(bytesRead % 2 == 0);

//		memcpy(jt9com_.d2[k],buf0,bytesRead);
//		k+=bytesRead/2;

		for(int i=0; i<bytesRead/2; i++) {
			jt9com_.d2[k++]=buf0[i];
		}

    if(m_monitoring) {
      int kstep=m_nsps/2;
      m_step=(k-1)/kstep;
      if(m_step != nstep0) {
        if(m_dataSinkBusy) {
          nBusy++;
        } else {
          emit readyForFFT(k-1);         //Signal to compute new FFTs
        }
        nstep0=m_step;
      }
    }
    msleep(100);
    ntr0=ntr;
  }
//  Pa_StopStream(inStream);
//  Pa_CloseStream(inStream);
}

void SoundInThread::setInputDevice(int n)                  //setInputDevice()
{
  if (isRunning()) return;
  this->m_nDevIn=n;
}

void SoundInThread::quit()                                       //quit()
{
  quitExecution = true;
}

void SoundInThread::setMonitoring(bool b)                    //setMonitoring()
{
  m_monitoring = b;
}

void SoundInThread::setPeriod(int ntrperiod, int nsps)
{
  m_TRperiod=ntrperiod;
  m_nsps=nsps;
}

int SoundInThread::mstep()
{
  return m_step;
}

