#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <inttypes.h>
#include <time.h>

extern void decode1_(int *iarg);
extern void a2d_(int *iarg);

int start_threads_(int *ndevin, int *ndevout, short y1[], short y2[],
	int *nbuflen, int *iwrite, short iwave[],
	int *nwave, int *nfsample, int *nsamperbuf,
	int *TRPeriod, int *TxOK, int *ndebug,
	int *Transmitting, double *Tsec, int *ngo, int *nmode,
	double tbuf[], int *ibuf, int *ndsec)
{
  pthread_t thread1,thread2;
  int iret1,iret2;
  int iarg1 = 1,iarg2 = 2;

 /* snd_pcm_start */
  //  printf("start_threads: creating thread for a2d\n");
  iret1 = pthread_create(&thread1,NULL,a2d_,&iarg1);
  //  printf("start_threads: creating thread for decode1_\n");
  iret2 = pthread_create(&thread2,NULL,decode1_,&iarg2);
}
