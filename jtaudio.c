#include <stdio.h>
#include <portaudio.h>

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
  gmtime_r(&tmptimeofday.tv_sec,&tmptmtime);
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

//  Input callback routine:
static int SoundIn( void *inputBuffer, void *outputBuffer,
		       unsigned long framesPerBuffer,
		       const PaStreamCallbackTimeInfo* timeInfo, 
		       PaStreamCallbackFlags statusFlags,
		       void *userData )
{
  paTestData *data = (paTestData*)userData;
  short *in = (short*)inputBuffer;
  short *wptr = (short*)outputBuffer;
  unsigned int i;
  static int n0;
  static int ia=0;
  static int ib=0;
  static int ic=0;
  static int TxOKz=0;
  static int ncall=0;
  static int nsec0=0;
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
  ncall++;

  // NB: inputBufferAdcTime and currentTime do not work properly.
  /*
  if(nsec!=nsec0) {
    printf("%f %f %f %f\n",stime,timeInfo->inputBufferAdcTime,
	   timeInfo->currentTime,timeInfo->outputBufferDacTime);
  }
  */

  //  if((inputBuffer==NULL) & (ncall>2) & (stime>stime0)) {
  if((statusFlags!=0) & (ncall>2) & (stime>stime0)) {
    if(*data->ndebug) 
      printf("Status flags %d at Tsec = %7.1f s, DT = %7.1f\n",stime,
	   stime-stime0);
    stime0=stime;
  }

  if((statusFlags&1)==0) {
    //increment buffer pointers only if data available
  ia=*data->iwrite;
  ib=*data->ibuf;
  ib++;                               //Increment ibuf
  if(ib>1024) ib=1; 
  *data->ibuf=ib;
  data->tbuf[ib-1]=stime;
    for(i=0; i<framesPerBuffer; i++) {
      data->y1[ia] = (*in++);
      data->y2[ia] = (*in++);
      ia++;
    }
  }

  if(ia >= data->nbuflen) ia=0;          //Wrap buffer pointer if necessary
  *data->iwrite = ia;                    //Save buffer pointer
  fivehz_();                             //Call fortran routine
  nsec0=nsec;
  return 0;
}

//  Output callback routine:
static int SoundOut( void *inputBuffer, void *outputBuffer,
		       unsigned long framesPerBuffer,
		       const PaStreamCallbackTimeInfo* timeInfo, 
		       PaStreamCallbackFlags statusFlags,
		       void *userData )
{
  paTestData *data = (paTestData*)userData;
  short *in = (short*)inputBuffer;
  short *wptr = (short*)outputBuffer;
  unsigned int i,n;
  static short n2;
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

  for(i=0 ; i<framesPerBuffer; i++ )  {
    if(*data->TxOK)  {
      addnoise_(&data->iwave[ic]);
      *wptr++ = data->iwave[ic];        //left
      *wptr++ = data->iwave[ic];        //right
      ic++;
      if(ic>=*data->nwave) {
	ic = ic % *data->nwave;       //Wrap buffer pointer if necessary
	if(*data->nmode==2)
	  *data->TxOK=0;
      }
    }
    else {
      n2=0;
      addnoise_(&n2);
      *wptr++ = n2;                     //left
      *wptr++ = n2;                     //right
    }
  }
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
  PaStream *instream;
  PaStream *outstream;
  PaStreamParameters inputParameters;
  PaStreamParameters outputParameters;
  PaStreamInfo *streamInfo;

  int i,nfs,ndin,ndout;
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
  printf("Opening device %d for input, %d for output.\n",ndin,ndout);

  inputParameters.device=*ndevin;
  inputParameters.channelCount=2;
  inputParameters.sampleFormat=paInt16;
  inputParameters.suggestedLatency=1.0;
  inputParameters.hostApiSpecificStreamInfo=NULL;
  err2=Pa_OpenStream(
		       &instream,       //address of stream
		       &inputParameters,
		       NULL,
		       dnfs,            //Sample rate
		       2048,            //Frames per buffer
		       paNoFlag,
		       SoundIn,         //Callback routine
		       &data);          //address of data structure
  if(err2) {
    printf("Error opening Audio stream for input.\n");
    printf("%s\n",Pa_GetErrorText(err2));
    goto error;
  }

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

  err3=Pa_StartStream(instream);             //Start input stream
  if(err3) {
    printf("Error starting input Audio stream\n");
    printf("%s\n",Pa_GetErrorText(err3));
    goto error;
  }
  err3a=Pa_StartStream(outstream);             //Start output stream
  if(err3a) {
    printf("Error starting output Audio stream\n");
    printf("%s\n",Pa_GetErrorText(err3a));
    goto error;
  }

  printf("Audio streams running normally.\n******************************************************************\n");

  while(Pa_IsStreamActive(instream))  {
    if(*ngo==0) goto StopStream;
    //    printf("CPU: %f\n",Pa_GetStreamCpuLoad(stream));
    Pa_Sleep(200);
  }

 StopStream:
  Pa_AbortStream(instream);              // Abort stream
  Pa_CloseStream(instream);             // Close stream, we're done.
  Pa_AbortStream(outstream);              // Abort stream
  Pa_CloseStream(outstream);             // Close stream, we're done.
  Pa_Terminate();
  return(0);

error:
  printf("%d  %d  %f  %d  %d  %d  %d  %d\n",ndin,ndout,dnfs,err1,
	 err2,err2a,err3,err3a);
  Pa_Terminate();
  return(1);
}


int padevsub_(int *numdev, int *ndefin, int *ndefout, 
	      int nchin[], int nchout[])
{
  int      i,j,n;
  int      numDevices;
  const    PaDeviceInfo *pdi;
  PaError  err;
  PaHostApiInfo *hostapi;
  
  Pa_Initialize();

  /*
  n=Pa_GetHostApiCount();
  printf("HostAPI Type #Devices \n");
  for(i=0; i<n; i++) {
    hostapi=Pa_GetHostApiInfo(i);
    printf(" %3d   %2d   %3d  %s\n",i,hostapi->type,
	   hostapi->deviceCount,hostapi->name);
  }
  */

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

