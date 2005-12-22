#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

extern void decode1_(int *iarg);
void start_threads_(void)
{
  pthread_t thread1,thread2;
  int iret1,iret2;
  int iarg1=1,iarg2=2;

  //  iret1 = pthread_create(&thread1,NULL,a2d_,&iarg1);
  iret2 = pthread_create(&thread2,NULL,decode1_,&iarg2);

}
