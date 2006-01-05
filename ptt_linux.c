#include <unistd.h>
#include <stdio.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/io.h>

int ptt_(int *nport, int *ntx, int *iptt)
{
  static int nopen=0;
  int control = TIOCM_RTS | TIOCM_DTR;
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

  if(*ntx && nopen) {
    //    printf("Set DTR/RTS   %d   %d\n",TIOCMBIS,control);
    ioctl(fd, TIOCMBIS, &control);               // Set DTR and RTS
    *iptt=1;
  }

  else {
    //    printf("Clear DTR/RTS   %d   %d\n",TIOCMBIC,control);
    ioctl(fd, TIOCMBIC, &control);
    close(fd);
    *iptt=0;
    nopen=0;
  }
  return(0);
}
