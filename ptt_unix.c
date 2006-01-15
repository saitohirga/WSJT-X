/*
 * WSJT is Copyright (c) 2001-2006 by Joseph H. Taylor, Jr., K1JT, 
 * and is licensed under the GNU General Public License (GPL).
 */

#include <unistd.h>
#include <stdio.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include "conf.h"	/* XXX Could use CFLAGS later instead --db */

#ifdef HAVE_SYS_PARAM_H
#include <sys/param.h>
#endif

/* First cut, note that this only distinguishes Linux from BSDs,
 * it will be done better later on using configure. N.B. that OSX
 * will come up as BSD but I think this is also the right serial port
 * for OSX. -db
 */
#if defined(BSD)
#define TTYNAME "/dev/cuad%d"	/* Use non blocking form */
#else
#include <sys/io.h>
#define TTYNAME	"/dev/ttyS%d"
#endif

/* Not quite right for size but '%d + 1' should be plenty enough -db */
#define TTYNAME_SIZE	sizeof(TTYNAME)+1

int
ptt_(int *nport, int *ntx, int *iptt)
{
  static int nopen=0;
  int control = TIOCM_RTS | TIOCM_DTR;
  int fd;
  char s[TTYNAME_SIZE];	

  if(*nport < 0) {
    *iptt=*ntx;
    return(0);
  }

  if(*ntx && (!nopen)) {
    snprintf(s, TTYNAME_SIZE, TTYNAME, (*nport) - 1);	/* Comport 1 == dev 0 */
    s[TTYNAME_SIZE] = '\0';

    /* open the device */
    if ((fd = open(s, O_RDWR | O_NDELAY)) < 0) {
      fprintf(stderr, "Can't open %s.", s);
      return(1);
    }

    nopen=1;
    return(0);
  }

  if(*ntx && nopen) {
    ioctl(fd, TIOCMBIS, &control);               // Set DTR and RTS
    *iptt=1;
  }

  else {
    ioctl(fd, TIOCMBIC, &control);
    close(fd);
    *iptt=0;
    nopen=0;
  }
  return(0);
}
