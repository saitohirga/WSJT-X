#include <unistd.h>
#include <stdio.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/io.h>

int ptt_(int *nport, int *ntx, int *iptt)
{
  static int nopen=0;
  int i;
  int fd;
  char s[11];

  if(*nport < 0) {
    *iptt=*ntx;
    return(0);
  }

  if(*ntx && (!nopen)) {
    sprintf(s,"/dev/ttyS%d",*nport);
    //open the device
    if ((fd = open(s, O_RDWR | O_NDELAY)) < 0) {
      fprintf(stderr, "device not found");
      return(1);
    }
    nopen=1;
    return(0);
  }

  //enable privileges for I/O port controls
  if(ioperm(0,0x3ff,1) < 0) {
    printf("Cannot set privileges for serial I/O\n");
    return(1);
  }

  //  ioctl(fd, TIOCMGET, &flags);   //get line bits for serial port

  if(*ntx && nopen) {
    i = TIOCM_RTS + TIOCM_DTR;
    ioctl(fd, TIOCMSET, &i);               // Set DTR and RTS
    *iptt=1;
  }

  else {
    i=0;
    ioctl(fd, TIOCMSET, &i);
    close(fd);
    *iptt=0;
    nopen=0;
  }
  return(0);
}
