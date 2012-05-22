#include "soundout.h"

#define FRAMES_PER_BUFFER 256

extern "C" {
#include <portaudio.h>
}

extern float gran();                  //Noise generator (for tests only)

extern short int iwave[60*11025];     //Wave file for Tx audio
extern int nwave;
extern bool btxok;
extern double outputLatency;

typedef struct   //Parameters sent to or received from callback function
{
  int dummy;
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
  unsigned int i,n;
  static int ic=0;
//  static int ic0=0;
//  static int nsec0=-99;
  static bool btxok0=false;
  static int nminStart=0;
//  static t0,t1;
  double tsec,tstart;

  int nsec;

  // Get System time
  qint64 ms = QDateTime::currentMSecsSinceEpoch() % 86400000;
  tsec = 0.001*ms;
  nsec = ms/1000;

  if(btxok and !btxok0) {       //Start (or re-start) a transmission
    n=nsec/60;
    tstart=tsec - n*60.0 - 1.0;

    if(tstart<1.0) {
      ic=0;                      //Start of minute, set starting index to 0
//      ic0=ic;
      nminStart=n;
//      t0=timeInfo->currentTime;
    } else {
      if(n != nminStart) { //Late start in new minute: compute starting index
        ic=(int)(tstart*11025.0);
//        ic0=ic;
//        t0=timeInfo->currentTime;
//        qDebug() << "B" << t0 << ic0;
        nminStart=n;
      }
    }
    /*
    qDebug() << "A" << n << ic
             << QString::number( tsec, 'f', 3 )
             << QString::number( tstart, 'f', 3 )
             << QString::number( timeInfo->currentTime, 'f', 3 )
             << QString::number( timeInfo->outputBufferDacTime, 'f', 3 )
             << QString::number( timeInfo->outputBufferDacTime -
                                 timeInfo->currentTime, 'f', 3 )
             << QString::number( timeInfo->currentTime - tsec, 'f', 3 );
    */
  }
  btxok0=btxok;

  /*
  if(nsec!=nsec0) {
    double txt=timeInfo->currentTime - t0;
    double r=0.0;
    if(txt>0.0) r=(ic-ic0)/txt;
    qDebug() << "C" << txt << ic-ic0 << r;
    nsec0=nsec;
  }
  */

  if(btxok) {
    for(i=0 ; i<framesToProcess; i++ )  {
      short int i2=iwave[ic];
      if(ic > nwave) i2=0;
//      i2 = 500.0*(i2/32767.0 + 5.0*gran());      //Add noise (tests only!)
      if(!btxok) i2=0;
      *wptr++ = i2;                   //left
      *wptr++ = i2;                   //right
      ic++;
    }
  } else {
    for(i=0 ; i<framesToProcess; i++ )  {
      *wptr++ = 0;
      *wptr++ = 0;
      ic++;
    }
  }
  if(ic > nwave) {
    btxok=0;
    ic=0;
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
  outParam.channelCount=2;                   //Number of analog channels
  outParam.sampleFormat=paInt16;             //Send short ints to PortAudio
  outParam.suggestedLatency=0.05;
  outParam.hostApiSpecificStreamInfo=NULL;

  paerr=Pa_IsFormatSupported(NULL,&outParam,11025.0);
  if(paerr<0) {
    qDebug() << "PortAudio says requested output format not supported.";
    qDebug() << paerr;
    return;
  }

//  udata.nwave=m_nwave;
//  udata.btxok=false;

  paerr=Pa_OpenStream(&outStream,           //Output stream
        NULL,                               //No input parameters
        &outParam,                          //Output parameters
        11025.0,                            //Sample rate
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
//    udata.nwave=m_nwave;
//    if(m_txOK) udata.btxok=1;
//    if(!m_txOK) udata.btxok=0;
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
