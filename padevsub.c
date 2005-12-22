// #include <stdio.h>
// #include <math.h>
#include "portaudio.h"

int __stdcall PADEVSUB(int *numdev, int *ndefin, int *ndefout,
		       int nchin[], int nchout[])
{
  int      i,j;
  int      numDevices;
  const    PaDeviceInfo *pdi;
  PaError  err;

  Pa_Initialize();
  numDevices = Pa_CountDevices();
  *numdev=numDevices;
  if( numDevices < 0 )  {
    err = numDevices;
    goto error;
  }

  for( i=0; i<numDevices; i++ )  {
    pdi = Pa_GetDeviceInfo( i );
    if(i == Pa_GetDefaultInputDeviceID()) *ndefin=i;
    if(i == Pa_GetDefaultOutputDeviceID()) *ndefout=i;
    nchin[i]=pdi->maxInputChannels;
    nchout[i]=pdi->maxOutputChannels;
    printf("Audio device %d: In=%d  Out=%d  %s\n",i,nchin[i],nchout[i],pdi->name);
  }

  Pa_Terminate();
  return 0;

 error:
  Pa_Terminate();
  return err;
}
