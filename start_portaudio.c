#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <inttypes.h>
#include <time.h>
#include <sys/time.h>

extern void a2d_(int *iarg);
extern void decode1_(int *iarg);
extern void recvpkt_(int *iarg);

int start_threads_(int *ndevin, int *ndevout, short y1[], short y2[],
	int *nbuflen, int *iwrite, short iwave[],
	int *nwave, int *nfsample, int *nsamperbuf,
	int *TRPeriod, int *TxOK, int *ndebug,
	int *Transmitting, double *Tsec, int *ngo, int *nmode,
	double tbuf[], int *ibuf, int *ndsec)
{
  pthread_t thread1,thread2,thread3;
  int iret1,iret2,iret3;
  int iarg1=1, iarg2=2, iarg3=3;

  iret1 = pthread_create(&thread1,NULL,
			 (void *)a2d_,&iarg1);
  iret2 = pthread_create(&thread2,NULL,
			 (void *)decode1_,&iarg2);
  iret3 = pthread_create(&thread3,NULL,
			 (void *)recvpkt_,&iarg3);
  return(iret1 | iret2 | iret3);
}
