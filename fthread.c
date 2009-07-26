/*
* fthread.c
*
* pthread library interface to Fortran, for OSs supporting pthreads
*
* Adapted from code by V. Ganesh
*/
#include <stdio.h>
#include <pthread.h>

// Create a new fortran thread through a subroutine.
void fthread_create_(void *(*thread_func)(void *), pthread_t *theThread) 
{
  pthread_create(theThread, NULL, thread_func, NULL);
} 

/*
// Yield control to other threads
void fthread_yield_() 
{
  pthread_yield();
}
*/

// Return my own thread ID
pthread_t fthread_self_() 
{
  return pthread_self();
} 

// Lock the execution of all threads until we have the mutex
int fthread_mutex_lock_(pthread_mutex_t **theMutex) 
{
  return(pthread_mutex_lock(*theMutex));
}

int fthread_mutex_trylock_(pthread_mutex_t **theMutex) 
{
  return(pthread_mutex_trylock(*theMutex));
}

// Unlock the execution of all threads that were stopped by this mutex
void fthread_mutex_unlock_(pthread_mutex_t **theMutex) 
{
  pthread_mutex_unlock(*theMutex);
}

// Get a new mutex object
void fthread_mutex_init_(pthread_mutex_t **theMutex) 
{
  *theMutex = (pthread_mutex_t *) malloc(sizeof(pthread_mutex_t));
  pthread_mutex_init(*theMutex, NULL);
}

// Release a mutex object
void fthread_mutex_destroy_(pthread_mutex_t **theMutex) 
{
  pthread_mutex_destroy(*theMutex);
  free(*theMutex);
}

// Waits for thread ID to join
void fthread_join(pthread_t *theThread) 
{
  int value = 0;
  pthread_join(*theThread, (void **)&value);
}

// Exit from a thread
void fthread_exit_(void *status) 
{
  pthread_exit(status);
}

