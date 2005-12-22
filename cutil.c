/*  FORTRAN:  fd = close(filedes)      */
close_(filedes)
int *filedes;
{
return(close(*filedes));
}
/*  FORTRAN:  fd = open(filnam,mode)  */
open_(filnam,mode)
char filnam[];
int *mode;
{
  return(open(filnam,*mode));
}
/* FORTRAN:  fd = creat(filnam,mode) */
creat_(filnam,mode)
char filnam[];
int *mode;
{
  return(creat(filnam,*mode));
}
/* FORTRAN:  nread = read(fd,buf,n) */
read_(fd,buf,n)
int *fd,*n;
char buf[];
{
  return(read(*fd,buf,*n));
}
/* FORTRAN:  nwrt = write(fd,buf,n) */
write_(fd,buf,n)
int *fd,*n;
char buf[];
{
  return(write(*fd,buf,*n));
}
/* FORTRAN: ns = lseek(fd,offset,origin) */
lseek_(fd,offset,origin)
int *fd,*offset,*origin;
{
  return(lseek(*fd,*offset,*origin));
}
/* times(2) */
times_(buf)
int buf[];
{
  return (times(buf));
}
/* ioperm(2) */
ioperm_(from,num,turn_on)
unsigned long *from,*num,*turn_on;
{
  return (ioperm(*from,*num,*turn_on));
}

/* usleep(3) */
usleep_(microsec)
unsigned long *microsec;
{
  return (usleep(*microsec));
}

/* returns random numbers between 0 and 32767 to FORTRAN program */
iran_(arg)
int *arg;
{
  return (rand());
}
exit_(n)
int *n;
{
  printf("\n\n");
  exit(*n);
}
#include <time.h>
time_t time_()
{
     return time(0);
}

/* hrtime() */
double hrtime_()
{
  int tv[2],tz[2];
  gettimeofday(tv,tz);
  return(tv[0]+1.e-6*tv[1]);
}
