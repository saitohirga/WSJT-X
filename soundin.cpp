#ifndef QAUDIO_INPUT
#include "soundin.h"

#include <QDateTime>
#include <QDebug>

#define FRAMES_PER_BUFFER 1024
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

//--------------------------------------------------------------- a2dCallback
int a2dCallback( const void *inputBuffer, void * /* outputBuffer */,
		 unsigned long framesToProcess,
		 const PaStreamCallbackTimeInfo * /* timeInfo */,
		 PaStreamCallbackFlags statusFlags,
		 void *userData )

// This routine called by the PortAudio engine when samples are available.
// It may be called at interrupt level, so don't do anything
// that could mess up the system like calling malloc() or free().

{
  SoundInput::CallbackData * udata = reinterpret_cast<SoundInput::CallbackData *>(userData);
  int nbytes,k;

  if( (statusFlags&paInputOverflow) != 0) {
    qDebug() << "Input Overflow in a2dCallback";
  }
  if(udata->bzero)
    { //Start of a new Rx sequence
      udata->kin = 0;		//Reset buffer pointer
      udata->bzero = false;
    }

  nbytes=2*framesToProcess;	//Bytes per frame
  k=udata->kin;
  if(udata->monitoring) {
    memcpy(&jt9com_.d2[k],inputBuffer,nbytes);      //Copy all samples to d2
  }
  udata->kin+=framesToProcess;
  jt9com_.kin=udata->kin; // we are the only writer to jt9com_ so no MT issue here

  return paContinue;
}

SoundInput::SoundInput()
  : m_inStream(0),
    m_TRperiod(60),
    m_nsps(6912),
    m_monitoring(false),
    m_intervalTimer(this)
{
	connect(&m_intervalTimer, SIGNAL(timeout()), this,SLOT(intervalNotify()));
}

void SoundInput::start(qint32 device)
{
  stop();

//---------------------------------------------------- Soundcard Setup
  PaError paerr;
  PaStreamParameters inParam;

  m_callbackData.kin = 0;	 //Buffer pointer
  m_callbackData.bzero = false;	 //Flag to request reset of kin
  m_callbackData.monitoring = m_monitoring;

  inParam.device=device;		    //### Input Device Number ###
  inParam.channelCount=1;                   //Number of analog channels
  inParam.sampleFormat=paInt16;             //Get i*2 from Portaudio
  inParam.suggestedLatency=0.05;
  inParam.hostApiSpecificStreamInfo=NULL;

  paerr=Pa_IsFormatSupported(&inParam,NULL,12000.0);
  if(paerr<0) {
    emit error("PortAudio says requested soundcard format not supported.");
  }
  paerr=Pa_OpenStream(&m_inStream, //Input stream
        &inParam,		   //Input parameters
        NULL,			   //No output parameters
        12000.0,		   //Sample rate
        FRAMES_PER_BUFFER,	   //Frames per buffer
//        paClipOff+paDitherOff,            //No clipping or dithering
        paClipOff,		//No clipping
        a2dCallback,		//Input callback routine
        &m_callbackData);	//userdata
  paerr=Pa_StartStream(m_inStream);
  if(paerr<0) {
    emit error("Failed to start audio input stream.");
    return;
  }
  m_ntr0 = 99;		     // initial value higher than any expected
  m_intervalTimer.start(100);
  m_ms0 = QDateTime::currentMSecsSinceEpoch();
  m_nsps0 = 0;
}

void SoundInput::intervalNotify()
{
  m_callbackData.monitoring = m_monitoring; // update monitoring
					    // status

  qint64 ms = QDateTime::currentMSecsSinceEpoch();
  ms=ms % 86400000;
  int nsec = ms/1000;             // Time according to this computer
  int ntr = nsec % m_TRperiod;

  int k=m_callbackData.kin;	// get a copy of kin to mitigate the
				// potential race condition with the
				// callback handler when a buffer
				// reset is requested below

  // Reset buffer pointer and symbol number at start of minute
  if(ntr < m_ntr0 or !m_monitoring or m_nsps!=m_nsps0) {
    m_nstep0=0;
    m_nsps0=m_nsps;
    m_callbackData.bzero = true; // request callback to reset buffer pointer
  }

  if(m_monitoring) {
    int kstep=m_nsps/2;
    //      m_step=k/kstep;
    m_step=(k-1)/kstep;
    if(m_step != m_nstep0) {
      emit readyForFFT(k-1);         //Signal to compute new FFTs
      m_nstep0=m_step;
    }
  }
  m_ntr0=ntr;
}

SoundInput::~SoundInput()
{
  if (m_inStream)
    {
      Pa_CloseStream(m_inStream), m_inStream = 0;
    }
}

void SoundInput::stop()
{
  m_intervalTimer.stop();
  if (m_inStream)
    {
      Pa_StopStream(m_inStream);
      Pa_CloseStream(m_inStream), m_inStream = 0;
    }
}

#else  // QAUDIO_INPUT

#include "soundin.h"

#include <QDateTime>

#define FRAMES_PER_BUFFER 1024
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

SoundInput::SoundInput()
	:	m_dataSinkBusy(false),
		m_TRperiod(60),
		m_nsps(6912),
		m_monitoring(false),
		m_intervalTimer(this)
{
//  qDebug() << "A";
  connect(&m_intervalTimer, SIGNAL(timeout()), this,SLOT(intervalNotify()));
}

void SoundInput::start(qint32 device)
{
	stop();

//---------------------------------------------------- Soundcard Setup
	m_callbackData.kin=0;                              //Buffer pointer
	m_callbackData.ncall=0;                            //Number of callbacks
	m_callbackData.bzero=false;                        //Flag to request reset of kin
	m_callbackData.monitoring=m_monitoring;

	//### Temporary: hardwired device selection
	QAudioDeviceInfo  DeviceInfo;
	QList<QAudioDeviceInfo> m_InDevices;
	QAudioDeviceInfo  m_InDeviceInfo;
	m_InDevices = DeviceInfo.availableDevices(QAudio::AudioInput);
	inputDevice = m_InDevices.at(0);
	//###
//  qDebug() << "B" << m_InDevices.length() << inputDevice.deviceName();

	const char* pcmCodec = "audio/pcm";
	QAudioFormat audioFormat = inputDevice.preferredFormat();
	audioFormat.setChannelCount(1);
	audioFormat.setCodec(pcmCodec);
	audioFormat.setSampleRate(12000);
	audioFormat.setSampleType(QAudioFormat::SignedInt);
	audioFormat.setSampleSize(16);

//  qDebug() << "C" << audioFormat << audioFormat.isValid();

	if (!audioFormat.isValid()) {
		emit error(tr("Requested audio format is not available."));
		return;
	}

	audioInput = new QAudioInput(inputDevice, audioFormat);
//  qDebug() << "D" << audioInput->error() << QAudio::NoError;
  if (audioInput->error() != QAudio::NoError) {
		emit error(reportAudioError(audioInput->error()));
		return;
	}

	stream = audioInput->start();
//  qDebug() << "E" << stream->errorString();

	m_ntr0 = 99;		     // initial value higher than any expected
	m_nBusy = 0;
	m_intervalTimer.start(100);
	m_ms0 = QDateTime::currentMSecsSinceEpoch();
	m_nsps0 = 0;
}

void SoundInput::intervalNotify()
{
	m_callbackData.monitoring=m_monitoring;
	qint64 ms = QDateTime::currentMSecsSinceEpoch();
	ms=ms % 86400000;
	int nsec = ms/1000;             // Time according to this computer
	int ntr = nsec % m_TRperiod;
	static int k=0;

//  qDebug() << "a" << ms << nsec;
  // Reset buffer pointer and symbol number at start of minute
	if(ntr < m_ntr0 or !m_monitoring or m_nsps!=m_nsps0) {
		m_nstep0=0;
		m_nsps0=m_nsps;
		m_callbackData.bzero=true;
		k=0;
	}
//	int k=m_callbackData.kin;

// How many new samples are available?
	const qint32 bytesReady = audioInput->bytesReady();
//  qDebug() << "b" << bytesReady;
  Q_ASSERT(bytesReady >= 0);
	Q_ASSERT(bytesReady % 2 == 0);
	if (bytesReady == 0) {
		return;
	}

	qint32 bytesRead;
  bytesRead = stream->read((char*)&jt9com_.d2[k], bytesReady);   // Get the new samples
  k += bytesRead/2;
//  qDebug() << "c" << bytesReady << bytesRead;
  Q_ASSERT(bytesRead <= bytesReady);
	if (bytesRead < 0) {
		emit error(tr("audio stream QIODevice::read returned -1."));
		return;
	}
	Q_ASSERT(bytesRead % 2 == 0);

	if(m_monitoring) {
		int kstep=m_nsps/2;
		m_step=(k-1)/kstep;
		if(m_step != m_nstep0) {
			if(m_dataSinkBusy) {
	m_nBusy++;
			} else {
	emit readyForFFT(k-1);         //Signal to compute new FFTs
			}
			m_nstep0=m_step;
		}
	}
	m_ntr0=ntr;
}

SoundInput::~SoundInput()
{
/*
	if (m_inStream)
		{
			Pa_CloseStream(m_inStream), m_inStream = 0;
		}
*/
}
/*
//		memcpy(jt9com_.d2[k],buf0,bytesRead);
//		k+=bytesRead/2;
  for(int i=0; i<bytesRead/2; i++) {
    jt9com_.d2[k++]=buf0[i];
  }
*/
void SoundInput::stop()
{
	m_intervalTimer.stop();
/*
	if (m_inStream)
		{
			Pa_StopStream(m_inStream);
			Pa_CloseStream(m_inStream), m_inStream = 0;
		}
*/
}

#endif // QAUDIO_INPUT
