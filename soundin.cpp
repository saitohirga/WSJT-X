#include "soundin.h"
#include <stdexcept>

#define NFFT 32768
#define FRAMES_PER_BUFFER 1024

extern "C" {
#include <portaudio.h>
extern struct {
  short int d2[30*48000];             //This is "common/datcom/..." in fortran
  int kin;
} datcom_;
}

typedef struct
{
  int kin;          //Parameters sent to/from the portaudio callback function
  bool bzero;
} paUserData;

//--------------------------------------------------------------- a2dCallback
extern "C" int a2dCallback( const void *inputBuffer, void *outputBuffer,
                         unsigned long framesToProcess,
                         const PaStreamCallbackTimeInfo* timeInfo,
                         PaStreamCallbackFlags statusFlags,
                         void *userData )

// This routine called by the PortAudio engine when samples are available.
// It may be called at interrupt level, so don't do anything
// that could mess up the system like calling malloc() or free().

{
  paUserData *udata=(paUserData*)userData;
  (void) outputBuffer;          //Prevent unused variable warnings.
  (void) timeInfo;
  (void) userData;
  int nbytes,k;

//  if(framesToProcess != -99)   return paContinue;    //###

  if( (statusFlags&paInputOverflow) != 0) {
    qDebug() << "Input Overflow";
  }
  if(udata->bzero) {           //Start of a new Rx sequence
    udata->kin=0;              //Reset buffer pointer
    udata->bzero=false;
  }

  nbytes=2*framesToProcess;        //Bytes per frame
  k=udata->kin;
  memcpy(&datcom_.d2[k],inputBuffer,nbytes);          //Copy all samples to d2
  udata->kin += framesToProcess;
  datcom_.kin=udata->kin;

  return paContinue;
}

void SoundInThread::run()                           //SoundInThread::run()
{
  quitExecution = false;

//---------------------------------------------------- Soundcard Setup
  PaError paerr;
  PaStreamParameters inParam;
  PaStream *inStream;
  paUserData udata;

  udata.kin=0;                              //Buffer pointer
  udata.bzero=false;                        //Flag to request reset of kin

  inParam.device=m_nDevIn;                  //### Input Device Number ###
  inParam.channelCount=1;                   //Number of analog channels
  inParam.sampleFormat=paInt16;             //Get i*2 from Portaudio
  inParam.suggestedLatency=0.05;
  inParam.hostApiSpecificStreamInfo=NULL;

  paerr=Pa_IsFormatSupported(&inParam,NULL,48000.0);
  if(paerr<0) {
    emit error("PortAudio says requested soundcard format not supported.");
//    return;
  }
  paerr=Pa_OpenStream(&inStream,            //Input stream
        &inParam,                           //Input parameters
        NULL,                               //No output parameters
        48000.0,                            //Sample rate
        FRAMES_PER_BUFFER,                  //Frames per buffer
//        paClipOff+paDitherOff,            //No clipping or dithering
        paClipOff,                          //No clipping
        a2dCallback,                        //Input callbeck routine
        &udata);                            //userdata

  paerr=Pa_StartStream(inStream);
  if(paerr<0) {
    emit error("Failed to start audio input stream.");
    return;
  }

  bool qe = quitExecution;
  int n30z=99;
  int k=0;
  int nsec;
  int n30;
  int nBusy=0;
  int nstep0=0;

//---------------------------------------------- Soundcard input loop
  while (!qe) {
    qe = quitExecution;
    if (qe) break;
    qint64 ms = QDateTime::currentMSecsSinceEpoch() % 86400000;
    nsec = ms/1000;             // Time according to this computer
    n30 = nsec % 30;

// Reset buffer pointer and symbol number at start of minute
    if(n30 < n30z or !m_monitoring) {
      nstep0=0;
      udata.bzero=true;
    }
    k=udata.kin;
    if(m_monitoring) {
      m_step=k/(2*6192);
      if(m_step != nstep0) {
        if(m_dataSinkBusy) {
          nBusy++;
        } else {
//          m_dataSinkBusy=true;
//          qDebug() << "A" << k;
          emit readyForFFT(k);         //Signal to compute new FFTs
        }
        nstep0=m_step;
      }
    }
    msleep(100);
    n30z=n30;
  }
  Pa_StopStream(inStream);
  Pa_CloseStream(inStream);
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


int SoundInThread::mstep()
{
  return m_step;
}
