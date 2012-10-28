#include "soundout.h"

#define FRAMES_PER_BUFFER 256

extern "C" {
#include <portaudio.h>
}

extern float gran();                  //Noise generator (for tests only)
extern int itone[85];                 //Tx audio tones for 85 symbols
extern double outputLatency;

typedef struct   //Parameters sent to or received from callback function
{
  double txsnrdb;
  int    nsps;
  int    ntrperiod;
  int    ntxfreq;
  bool   txOK;
  bool   txMute;
  bool   bRestart;
} paUserData;

//--------------------------------------------------------------- d2aCallback
extern "C" int d2aCallback(const void *inputBuffer, void *outputBuffer,
                           unsigned long framesToProcess,
                           const PaStreamCallbackTimeInfo* timeInfo,
                           PaStreamCallbackFlags statusFlags,
                           void *userData )
{
  paUserData *udata=(paUserData*)userData;
  short *wptr = (short*)outputBuffer;

  static double twopi=2.0*3.141592653589793238462;
  static double baud;
  static double phi=0.0;
  static double dphi;
  static double freq;
  static double snr;
  static double fac;
  static int ic=0;
  static int isym0=-99;
  static short int i2;
  int isym;

  if(udata->bRestart) {
 // Time according to this computer
    qint64 ms = QDateTime::currentMSecsSinceEpoch() % 86400000;
    int mstr = ms % (1000*udata->ntrperiod );
    if(mstr<1000) return 0;
    ic=(mstr-1000)*12;
    udata->bRestart=false;
  }
  isym=ic/udata->nsps;
  if(isym>=85) return 0;
  baud=12000.0/udata->nsps;
  freq=udata->ntxfreq + itone[isym]*baud;
  dphi=twopi*freq/12000.0;
  if(udata->txsnrdb < 0.0) {
    snr=pow(10.0,0.05*(udata->txsnrdb-1.0));
    fac=3000.0;
    if(snr>1.0) fac=3000.0/snr;
  }

  for(uint i=0 ; i<framesToProcess; i++ )  {
    phi += dphi;
    if(phi>twopi) phi -= twopi;
    i2=32767.0*sin(phi);
//      i2 = 500.0*(i2/32767.0 + 5.0*gran());      //Add noise (tests only!)
    if(udata->txsnrdb < 0.0) {
      int i4=fac*(gran() + i2*snr/32768.0);
      if(i4>32767) i4=32767;
      if(i4<-32767) i4=-32767;
      i2=i4;
    }
    /*
    if(udata->txMute) i2=0;
    if(!udata->txOK)  i2=0;
    if(ic > 85*udata->nsps) i2=0;
    */
    *wptr++ = i2;                   //left
    ic++;
  }
  return 0;
}

void SoundOutThread::run()
{
  PaError paerr;
  PaStreamParameters outParam;
  PaStream *outStream;
  paUserData udata;
  quitExecution = false;

  outParam.device=m_nDevOut;                 //Output device number
  outParam.channelCount=1;                   //Number of analog channels
  outParam.sampleFormat=paInt16;             //Send short ints to PortAudio
  outParam.suggestedLatency=0.05;
  outParam.hostApiSpecificStreamInfo=NULL;

  paerr=Pa_IsFormatSupported(NULL,&outParam,12000.0);
  if(paerr<0) {
    qDebug() << "PortAudio says requested output format not supported.";
    qDebug() << paerr << m_nDevOut;
    return;
  }

  udata.txsnrdb=99.0;
  udata.nsps=m_nsps;
  udata.ntrperiod=m_TRperiod;
  udata.ntxfreq=m_txFreq;
  udata.txOK=false;
  udata.txMute=m_txMute;
  udata.bRestart=true;

  paerr=Pa_OpenStream(&outStream,           //Output stream
        NULL,                               //No input parameters
        &outParam,                          //Output parameters
        12000.0,                            //Sample rate
        FRAMES_PER_BUFFER,                  //Frames per buffer
        paClipOff,                          //No clipping
        d2aCallback,                        //output callbeck routine
        &udata);                            //userdata

  paerr=Pa_StartStream(outStream);
  if(paerr<0) {
    qDebug() << "Failed to start audio output stream.";
    return;
  }
  const PaStreamInfo* p=Pa_GetStreamInfo(outStream);
  outputLatency = p->outputLatency;
  bool qe = quitExecution;

//---------------------------------------------- Soundcard output loop
  while (!qe) {
    qe = quitExecution;
    if (qe) break;

    udata.txsnrdb=m_txsnrdb;
    udata.nsps=m_nsps;
    udata.ntrperiod=m_TRperiod;
    udata.ntxfreq=m_txFreq;
    udata.txOK=m_txOK;
    udata.txMute=m_txMute;
    msleep(100);
  }
  Pa_StopStream(outStream);
  Pa_CloseStream(outStream);
}

void SoundOutThread::setOutputDevice(int n)      //setOutputDevice()
{
  if (isRunning()) return;
  this->m_nDevOut=n;
}

void SoundOutThread::setPeriod(int ntrperiod, int nsps)
{
  m_TRperiod=ntrperiod;
  m_nsps=nsps;
}

void SoundOutThread::setTxFreq(int n)
{
  m_txFreq=n;
}


void SoundOutThread::setTxSNR(double snr)
{
  m_txsnrdb=snr;
}
