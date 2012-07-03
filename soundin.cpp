#include "soundin.h"
#include <stdexcept>

#define NFFT 32768
#define FRAMES_PER_BUFFER 1024

extern "C" {
#include <portaudio.h>
extern struct {
  double d8[2*60*96000];   //This is "common/datcom/..." in fortran
  float ss[4*322*NFFT];
  float savg[4*NFFT];
  double fcenter;
  int nutc;
  int idphi;                        //Phase correction for Y pol'n, degrees
  int mousedf;                      //User-selected DF
  int mousefqso;                    //User-selected QSO freq (kHz)
  int nagain;                       //1 ==> decode only at fQSO +/- Tol
  int ndepth;                       //How much hinted decoding to do?
  int ndiskdat;                     //1 ==> data read from *.tf2 or *.iq file
  int neme;                         //Hinted decoding tries only for EME calls
  int newdat;                       //1 ==> new data, must do long FFT
  int nfa;                          //Low decode limit (kHz)
  int nfb;                          //High decode limit (kHz)
  int nfcal;                        //Frequency correction, for calibration (Hz)
  int nfshift;                      //Shift of displayed center freq (kHz)
  int mcall3;                       //1 ==> CALL3.TXT has been modified
  int ntimeout;                     //Max for timeouts in Messages and BandMap
  int ntol;                         //+/- decoding range around fQSO (Hz)
  int nxant;                        //1 ==> add 45 deg to measured pol angle
  int map65RxLog;                   //Flags to control log files
  int nfsample;                     //Input sample rate
  int nxpol;                        //1 if using xpol antennas, 0 otherwise
  int mode65;                       //JT65 sub-mode: A=1, B=2, C=4
  char mycall[12];
  char mygrid[6];
  char hiscall[12];
  char hisgrid[6];
  char datetime[20];
} datcom_;
}

typedef struct
{
  int kin;          //Parameters sent to/from the portaudio callback function
  int nrx;
  bool bzero;
  bool iqswap;
  bool b10db;
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
  int nbytes,i,j;
  float d4[4*FRAMES_PER_BUFFER];
  float d4a[4*FRAMES_PER_BUFFER];
  float tmp;
  float fac;

  if(framesToProcess != -99)   return paContinue;    //###

  if( (statusFlags&paInputOverflow) != 0) {
    qDebug() << "Input Overflow";
  }
  if(udata->bzero) {           //Start of a new minute
    udata->kin=0;              //Reset buffer pointer
    udata->bzero=false;
  }

  nbytes=udata->nrx*8*framesToProcess;        //Bytes per frame
  memcpy(d4,inputBuffer,nbytes);              //Copy all samples to d4

  fac=32767.0;
  if(udata->b10db) fac=103618.35;

  if(udata->nrx==2) {
    for(i=0; i<4*int(framesToProcess); i++) {     //Negate odd-numbered frames
      d4[i]=fac*d4[i];
      j=i/4;
      if((j%2)==1) d4[i]=-d4[i];
    }
    if(!udata->iqswap) {
      for(i=0; i<int(framesToProcess); i++) {
        j=4*i;
        tmp=d4[j];
        d4[j]=d4[j+1];
        d4[j+1]=tmp;
        tmp=d4[j+2];
        d4[j+2]=d4[j+3];
        d4[j+3]=tmp;
      }
    }
    memcpy(&datcom_.d8[2*udata->kin],d4,nbytes); //Copy from d4 to dd()
  } else {
    int k=0;
    for(i=0; i<2*int(framesToProcess); i+=2) {    //Negate odd-numbered frames
      j=i/2;
      if(j%2==0) {
        d4a[k++]=fac*d4[i];
        d4a[k++]=fac*d4[i+1];
      } else {
        d4a[k++]=-fac*d4[i];
        d4a[k++]=-fac*d4[i+1];
      }
      d4a[k++]=0.0;
      d4a[k++]=0.0;
    }
    if(!udata->iqswap) {
      for(i=0; i<int(framesToProcess); i++) {
        j=4*i;
        tmp=d4a[j];
        d4a[j]=d4a[j+1];
        d4a[j+1]=tmp;
      }
    }
    memcpy(&datcom_.d8[2*udata->kin],d4a,2*nbytes); //Copy from d4a to dd()
  }
  udata->kin += framesToProcess;
  return paContinue;
}

void SoundInThread::run()                           //SoundInThread::run()
{
  quitExecution = false;

//---------------------------------------------------- Soundcard Setup
  qDebug() << "Start souncard input";

  PaError paerr;
  PaStreamParameters inParam;
  PaStream *inStream;
  paUserData udata;

  udata.kin=0;                              //Buffer pointer
  udata.bzero=false;                        //Flag to request reset of kin

  inParam.device=m_nDevIn;                  //### Input Device Number ###
  inParam.channelCount=2;                   //Number of analog channels
  inParam.sampleFormat=paFloat32;           //Get floats from Portaudio
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
//        paClipOff+paDitherOff,              //No clipping or dithering
        paClipOff,                          //No clipping
        a2dCallback,                        //Input callbeck routine
        &udata);                            //userdata

  paerr=Pa_StartStream(inStream);
  if(paerr<0) {
    emit error("Failed to start audio input stream.");
    return;
  }
//  const PaStreamInfo* p=Pa_GetStreamInfo(inStream);

  bool qe = quitExecution;
  int n30z=99;
  int k=0;
  int nsec;
  int n30;
  int nBusy=0;
  int nhsym0=0;

//---------------------------------------------- Soundcard input loop
  while (!qe) {
    qe = quitExecution;
    if (qe) break;
    qint64 ms = QDateTime::currentMSecsSinceEpoch() % 86400000;
    nsec = ms/1000;             // Time according to this computer
    n30 = nsec % 30;

// Reset buffer pointer and symbol number at start of minute
    if(n30 < n30z or !m_monitoring) {
      nhsym0=0;
      udata.bzero=true;
    }
    k=udata.kin;
    if(m_monitoring) {
      m_hsym=(k-2048)*11025.0/(2048.0*m_rate);
      if(m_hsym != nhsym0) {
        if(m_dataSinkBusy) {
          nBusy++;
        } else {
          m_dataSinkBusy=true;
//          emit readyForFFT(k);         //Signal to compute new FFTs
        }
        nhsym0=m_hsym;
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


int SoundInThread::mhsym()
{
  return m_hsym;
}
