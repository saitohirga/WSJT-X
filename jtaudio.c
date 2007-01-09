#include <stdio.h>
#include <portaudio.h>
#include <string.h>

void fivehz_();
void fivehztx_();
void addnoise_(short int *n);

//  Definition of structure pointing to the audio data
typedef struct
{
  double *Tsec;
  double *tbuf;
  int    *iwrite;
  int    *ibuf;
  int    *TxOK;
  int    *ndebug;
  int    *ndsec;
  int    *Transmitting;
  int    *nwave;
  int    *nmode;
  int    *trperiod;
  int     nbuflen;
  int     nfs;
  short  *y1;
  short  *y2;
  short  *iwave;
}
paTestData;

typedef struct _SYSTEMTIME
{
  short   Year;
  short   Month;
  short   DayOfWeek;
  short   Day;
  short   Hour;
  short   Minute;
  short   Second;
  short   Millisecond;
} SYSTEMTIME;

#ifdef Win32
extern void __stdcall GetSystemTime(SYSTEMTIME *st);
#else
#include <sys/time.h>
#include <time.h>

void GetSystemTime(SYSTEMTIME *st){
  struct timeval tmptimeofday;
  struct tm tmptmtime;
  gettimeofday(&tmptimeofday,NULL);
  gmtime_r((const time_t *)&tmptimeofday.tv_sec,&tmptmtime);
  st->Year = (short)tmptmtime.tm_year;
  st->Month = (short)tmptmtime.tm_year;
  st->DayOfWeek = (short)tmptmtime.tm_wday;
  st->Day = (short)tmptmtime.tm_mday;
  st->Hour = (short)tmptmtime.tm_hour;
  st->Minute = (short)tmptmtime.tm_min;
  st->Second = (short)tmptmtime.tm_sec;
  st->Millisecond = (short)(tmptimeofday.tv_usec/1000);
}
#endif

//  Output callback routine:
static int SoundOut( void *inputBuffer, void *outputBuffer,
		       unsigned long framesPerBuffer,
		       const PaStreamCallbackTimeInfo* timeInfo, 
		       PaStreamCallbackFlags statusFlags,
		       void *userData )
{
  paTestData *data = (paTestData*)userData;
  short *wptr = (short*)outputBuffer;
  unsigned int i,n;
  static short int n2;
  static int n0;
  static int ia=0;
  static int ib=0;
  static int ic=0;
  static int TxOKz=0;
  static double stime0=86400.0;
  int nsec;
  double stime;
  SYSTEMTIME st;

  // Get System time
  GetSystemTime(&st);
  nsec = (int) (st.Hour*3600.0 + st.Minute*60.0 + st.Second);
  stime = nsec + st.Millisecond*0.001 + *data->ndsec*0.1;
  *data->Tsec = stime;
  nsec=(int)stime;

  if(*data->TxOK && (!TxOKz))  {
    n=nsec/(*data->trperiod);
    //    ic = (int)(stime - *data->trperiod*n) * data->nfs/framesPerBuffer;
    //    ic = framesPerBuffer*ic;
    ic = (int)(stime - *data->trperiod*n) * data->nfs;
    ic = ic % *data->nwave;
  }

  TxOKz=*data->TxOK;
  *data->Transmitting=*data->TxOK;

  if(*data->TxOK)  {
    for(i=0 ; i<framesPerBuffer; i++ )  {
      n2=data->iwave[ic];
      addnoise_(&n2);
      *wptr++ = n2;                   //left
      *wptr++ = n2;                   //right
      ic++;
      if(ic>=*data->nwave) {
	if(*data->nmode==2) {
	  *data->TxOK=0;
	  ic--;
	}
	else
	  ic = ic % *data->nwave;       //Wrap buffer pointer if necessary
      }
    }
  } else {
    memset((void*)outputBuffer, 0, 2*sizeof(short)*framesPerBuffer);
  }
  fivehz_();                               //Call fortran routine
  fivehztx_();                             //Call fortran routine
  return 0;
}

/*******************************************************************/
int jtaudio_(int *ndevin, int *ndevout, short y1[], short y2[], 
	     int *nbuflen, int *iwrite, short iwave[], 
	     int *nwave, int *nfsample, int *nsamperbuf,
	     int *TRPeriod, int *TxOK, int *ndebug,
 	     int *Transmitting, double *Tsec, int *ngo, int *nmode,
	     double tbuf[], int *ibuf, int *ndsec)
{
  paTestData data;
  PaStream *outstream;
  PaStreamParameters outputParameters;

  int nfs,ndin,ndout;
  PaError err1,err2,err2a,err3,err3a;
  double dnfs;

  data.Tsec = Tsec;
  data.tbuf = tbuf;
  data.iwrite = iwrite;
  data.ibuf = ibuf;
  data.TxOK = TxOK;
  data.ndebug = ndebug;
  data.ndsec = ndsec;
  data.Transmitting = Transmitting;
  data.y1 = y1;
  data.y2 = y2;
  data.nbuflen = *nbuflen;
  data.nmode = nmode;
  data.nwave = nwave;
  data.iwave = iwave;
  data.nfs = *nfsample;
  data.trperiod = TRPeriod;

  nfs=*nfsample;
  err1=Pa_Initialize();                      // Initialize PortAudio
  if(err1) {
    printf("Error initializing PortAudio.\n");
    printf("%s\n",Pa_GetErrorText(err1));
    goto error;
  }

  ndin=*ndevin;
  ndout=*ndevout;
  dnfs=(double)nfs;
  printf("Opening device %d for output.\n",ndout);

  outputParameters.device=*ndevout;
  outputParameters.channelCount=2;
  outputParameters.sampleFormat=paInt16;
  outputParameters.suggestedLatency=1.0;
  outputParameters.hostApiSpecificStreamInfo=NULL;
  err2a=Pa_OpenStream(
		       &outstream,      //address of stream
		       NULL,
		       &outputParameters,
		       dnfs,            //Sample rate
		       2048,            //Frames per buffer
		       paNoFlag,
		       SoundOut,        //Callback routine
		       &data);          //address of data structure
  if(err2a) {
    printf("Error opening Audio stream for output.\n");
    printf("%s\n",Pa_GetErrorText(err2a));
    goto error;
  }

  err3a=Pa_StartStream(outstream);             //Start output stream
  if(err3a) {
    printf("Error starting output Audio stream\n");
    printf("%s\n",Pa_GetErrorText(err3a));
    goto error;
  }

  printf("Audio output stream running normally.\n******************************************************************\n");

  while(Pa_IsStreamActive(outstream))  {
    if(*ngo==0) goto StopStream;
    Pa_Sleep(200);
  }

 StopStream:
  Pa_AbortStream(outstream);              // Abort stream
  Pa_CloseStream(outstream);             // Close stream, we're done.
  Pa_Terminate();
  return(0);

error:
  printf("%d  %f  %d  %d  %d\n",ndout,dnfs,err1,err2a,err3a);
  Pa_Terminate();
  return(1);
}


int padevsub_(int *numdev, int *ndefin, int *ndefout, 
	      int nchin[], int nchout[])
{
  int      i;
  int      numDevices;
  const    PaDeviceInfo *pdi;
  PaError  err;
  //  PaHostApiInfo *hostapi;
  
  Pa_Initialize();

  //  numDevices = Pa_CountDevices();
  numDevices = Pa_GetDeviceCount();
  *numdev=numDevices;
  if( numDevices < 0 )  {
    err = numDevices;
    goto error;
  }


  printf("\nAudio     Input    Output     Device Name\n");
  printf("Device  Channels  Channels\n");
  printf("------------------------------------------------------------------\n");

  for( i=0; i<numDevices; i++ )  {
    pdi = Pa_GetDeviceInfo( i );
    //    if(i == Pa_GetDefaultInputDeviceID()) *ndefin=i;
    //    if(i == Pa_GetDefaultOutputDeviceID()) *ndefout=i;
    if(i == Pa_GetDefaultInputDevice()) *ndefin=i;
    if(i == Pa_GetDefaultOutputDevice()) *ndefout=i;
    nchin[i]=pdi->maxInputChannels;
    nchout[i]=pdi->maxOutputChannels;
    printf("  %2d       %2d        %2d       %s\n",i,nchin[i],nchout[i],pdi->name);
  }

  Pa_Terminate();
  return 0;

 error:
  Pa_Terminate();
  return err;
}

