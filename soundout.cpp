#include "soundout.h"

#include <cmath>
#include <cstring>

#include <QDateTime>
#include <QDebug>

//#define FRAMES_PER_BUFFER 1024

extern float gran();                  //Noise generator (for tests only)
extern int itone[126];                //Audio tones for all Tx symbols
extern int icw[250];                  //Dits for CW ID
extern int outBufSize;


//--------------------------------------------------------------- d2aCallback
int d2aCallback(const void *inputBuffer, void *outputBuffer,
                           unsigned long framesToProcess,
                           const PaStreamCallbackTimeInfo* timeInfo,
                           PaStreamCallbackFlags statusFlags,
                           void *userData )
{
  SoundOutput::CallbackData * udata = reinterpret_cast<SoundOutput::CallbackData *>(userData);
  short * wptr = reinterpret_cast<short *>(outputBuffer);

  static double twopi=2.0*3.141592653589793238462;
  static double baud;
  static double phi=0.0;
  static double dphi;
  static double freq;
  static double snr;
  static double fac;
  static double amp;
  static int ic=0,j=0;
  static int isym0=-999;
  static short int i2;
  int isym,nspd;

  udata->ncall++;
  if(udata->bRestart) {
 // Time according to this computer
    qint64 ms = QDateTime::currentMSecsSinceEpoch() % 86400000;
    int mstr = ms % (1000*udata->ntrperiod );
    if(mstr<1000)
      {
	std::memset(wptr, 0, framesToProcess * sizeof(*wptr)); // output silence
	return paContinue;
      }
    ic=(mstr-1000)*48;
    udata->bRestart=false;
    srand(mstr);                                //Initialize random seed
  }
  isym=ic/(4.0*udata->dnsps);                   //Actual fsample=48000
  if(udata->tune) isym=0;                      //If tuning, send pure tone
  if(udata->txsnrdb < 0.0) {
    snr=std::pow(10.0,0.05*(udata->txsnrdb-6.0));
    fac=3000.0;
    if(snr>1.0) fac=3000.0/snr;
  }

  if(isym>=udata->nsym and icw[0]>0) {              //Output the CW ID
    freq=udata->ntxfreq - udata->xit;
    dphi=twopi*freq/48000.0;

//    float wpm=20.0;
//    int nspd=1.2*48000.0/wpm;
//    nspd=3072;                           //18.75 WPM
    nspd=2048 + 512;                       //22.5 WPM
    int ic0=udata->nsym*4*udata->dnsps;
    for(uint i=0 ; i<framesToProcess; i++ )  {
      phi += dphi;
      if(phi>twopi) phi -= twopi;
      i2=32767.0*std::sin(phi);
      j=(ic-ic0)/nspd + 1;
      if(icw[j]==0) i2=0;
      if(udata->txsnrdb < 0.0) {
        int i4=fac*(gran() + i2*snr/32768.0);
        if(i4>32767) i4=32767;
        if(i4<-32767) i4=-32767;
        i2=i4;
      }
      if(udata->mute)  i2=0;
      *wptr++ = i2;                   //left
#ifdef UNIX
      *wptr++ = i2;                   //right
#endif
      ic++;
    }
    if(j>icw[0]) return paComplete;
    if(statusFlags==999999 and timeInfo==NULL and
       inputBuffer==NULL) return paContinue;   //Silence compiler warning:
    return paContinue;
  }

  baud=12000.0/udata->dnsps;
  amp=32767.0;
  int i0=(udata->nsym-0.017)*4.0*udata->dnsps;
  int i1=udata->nsym*4.0*udata->dnsps;
  bool tune = udata->tune;
  if(tune) {                           //If tuning, no ramp down
    i0=999*udata->dnsps;
    i1=i0;
  }
  for(uint i=0 ; i<framesToProcess; i++ )  {
    isym=ic/(4.0*udata->dnsps);                   //Actual fsample=48000
    if(tune) isym=0;                      //If tuning, send pure tone
    if(isym!=isym0) {
      freq=udata->ntxfreq + itone[isym]*baud - udata->xit;
      dphi=twopi*freq/48000.0;
      isym0=isym;
    }
    phi += dphi;
    if(phi>twopi) phi -= twopi;
    if(ic>i0) amp=0.98*amp;
    if(ic>i1) amp=0.0;
    i2=amp*std::sin(phi);
    if(udata->txsnrdb < 0.0) {
      int i4=fac*(gran() + i2*snr/32768.0);
      if(i4>32767) i4=32767;
      if(i4<-32767) i4=-32767;
      i2=i4;
    }
    if(udata->mute)  i2=0;
    *wptr++ = i2;                   //left
#ifdef UNIX
    *wptr++ = i2;                   //right
#endif
    ic++;
  }
  if(amp==0.0) {
    if(icw[0]==0) return paComplete;
    phi=0.0;
  }
  return paContinue;
}

SoundOutput::SoundOutput()
  : m_stream(0)
  , m_outputLatency(0.)
  , m_active(false)
{
}

void SoundOutput::start(qint32 deviceNumber,QString const& mode,int TRPeriod
			,int nsps,int txFreq,int xit,double txsnrdb)
{
  stop();

  PaStreamParameters outParam;

  outParam.device=deviceNumber;              //Output device number
  outParam.channelCount=1;                   //Number of analog channels
#ifdef UNIX
  outParam.channelCount=2;                   //Number of analog channels
#endif
  outParam.sampleFormat=paInt16;             //Send short ints to PortAudio
  outParam.suggestedLatency=0.05;
  outParam.hostApiSpecificStreamInfo=NULL;

  PaError paerr = Pa_IsFormatSupported(NULL,&outParam,48000.0);
  if(paerr<0) {
    qDebug() << "PortAudio says requested output format not supported.";
    qDebug() << paerr << deviceNumber;
    return;
  }

  m_callbackData.txsnrdb=txsnrdb;
  m_callbackData.dnsps=nsps;
  m_callbackData.nsym=85;
  if(mode=="JT65") {
    m_callbackData.dnsps=4096.0*12000.0/11025.0;
    m_callbackData.nsym=126;
  }
  m_callbackData.ntrperiod=TRPeriod;
  m_callbackData.ntxfreq=txFreq;
  m_callbackData.xit=xit;
  m_callbackData.ncall=0;
  m_callbackData.bRestart=true;

  paerr=Pa_OpenStream(&m_stream,            //Output stream
        NULL,                               //No input parameters
        &outParam,                          //Output parameters
        48000.0,                            //Sample rate
        outBufSize,                         //Frames per buffer
        paClipOff,                          //No clipping
        d2aCallback,                        //output callbeck routine
        &m_callbackData);                   //userdata

  paerr=Pa_StartStream(m_stream);
  if(paerr<0) {
    qDebug() << "Failed to start audio output stream.";
    return;
  }
  const PaStreamInfo* p=Pa_GetStreamInfo(m_stream);
  m_outputLatency = p->outputLatency;
  m_ms0 = QDateTime::currentMSecsSinceEpoch();
  m_active = true;
}

void SoundOutput::stop()
{
  if (m_stream)
    {
      Pa_StopStream(m_stream);
      Pa_CloseStream(m_stream), m_stream = 0;
    }
  m_active = false;
}

SoundOutput::~SoundOutput()
{
  if (m_stream)
    {
      Pa_CloseStream(m_stream), m_stream = 0;
    }
}
