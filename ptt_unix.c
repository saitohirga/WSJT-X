/*
 * WSJT is Copyright (c) 2001-2006 by Joseph H. Taylor, Jr., K1JT, 
 * and is licensed under the GNU General Public License (GPL).
 *
 * Code used from cwdaemon for parallel port ptt only.
 *
 * cwdaemon - morse sounding daemon for the parallel or serial port
 * Copyright (C) 2002 -2005 Joop Stakenborg <pg4i@amsat.org>
 *                       and many authors, see the AUTHORS file.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */
# if HAVE_STDIO_H
# include <stdio.h>
#endif
#if STDC_HEADERS
# include <stdlib.h>
# include <stddef.h>
#else
# if HAVE_STDLIB_H
#  include <stdlib.h>
# endif
#endif
#if HAVE_UNISTD_H
# include <unistd.h>
#endif
#if HAVE_SYS_IOCTL_H
# include <sys/ioctl.h>
#endif
#if HAVE_FCNTL_H
# include <fcntl.h>
#endif

#ifdef HAVE_SYS_STAT_H
# include <sys/stat.h>
#endif
#if (defined(__unix__) || defined(unix)) && !defined(USG)
# include <sys/param.h>
#endif

int fd;			/* Used for both serial and parallel */

#ifdef USE_SERIAL

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
      fprintf(stderr, "Can't open %s.\n", s);
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
#endif

#ifdef USE_PARALLEL

#ifdef HAVE_LINUX_PPDEV_H
# include <linux/ppdev.h>
# include <linux/parport.h>
#endif
#ifdef HAVE_DEV_PPBUS_PPI_H
# include <dev/ppbus/ppi.h>
# include <dev/ppbus/ppbconf.h>
#endif
#ifdef HAVE_SYS_STAT_H
# include <sys/stat.h>
#endif
#if (defined(__unix__) || defined(unix)) && !defined(USG)
# include <sys/param.h>
#endif

/* parport functions */

int lp_reset (int fd);
int lp_ptt (int fd, int onoff);

/*
 * dev_is_parport(name): check to see whether 'name' is a parallel
 *     port type character device.  Returns non-zero if the device is
 *     capable of use for a parallel port based keyer, and zero if it
 *     is not.  Unfortunately, this is platform specific.
 */

#if defined(HAVE_LINUX_PPDEV_H)                /* Linux (ppdev) */

int
dev_is_parport(const char *fname)
{
       char nm[MAXPATHLEN];
       struct stat st;
       int fd, m;

       m = snprintf(nm, sizeof(nm), "/dev/%s", fname);
       if (m >= sizeof(nm))
               return (-1);
       if ((fd = open(nm, O_RDWR | O_NONBLOCK)) == -1)
               return (-1);
       if (fstat(fd, &st) == -1)
               goto out;
       if ((st.st_mode & S_IFMT) != S_IFCHR)
               goto out;
       if (ioctl(fd, PPGETMODE, &m) == -1)
               goto out;
       return (fd);
out:
       close(fd);
       return (-1);
}

#elif defined(HAVE_DEV_PPBUS_PPI_H)    /* FreeBSD (ppbus/ppi) */

int
dev_is_parport(const char *fname)
{
       char nm[MAXPATHLEN];
       struct stat st;
       unsigned char c;
       int fd, m;

       m = snprintf(nm, sizeof(nm), "/dev/%s", fname);
       if (m >= sizeof(nm))
               return (-1);
       if ((fd = open(nm, O_RDWR | O_NONBLOCK)) == -1)
               return (-1);
       if (fstat(fd, &st) == -1)
               goto out;
       if ((st.st_mode & S_IFMT) != S_IFCHR)
               goto out;
       if (ioctl(fd, PPISSTATUS, &c) == -1)
               goto out;
       return (fd);
out:
       close(fd);
       return (-1);
}

#else                                  /* Fallback (nothing) */

int
dev_is_parport(const char *fname)
{
       return (-1);
}

#endif
/* Linux wrapper around PPFCONTROL */
#ifdef HAVE_LINUX_PPDEV_H
static void
parport_control (int fd, unsigned char controlbits, int values)
{
	struct ppdev_frob_struct frob;
	frob.mask = controlbits;
	frob.val = values;

	if (ioctl (fd, PPFCONTROL, &frob) == -1)
	{
		fprintf(stderr, "Parallel port PPFCONTROL");
		exit (1);
	}
}
#endif

/* FreeBSD wrapper around PPISCTRL */
#ifdef HAVE_DEV_PPBUS_PPI_H
static void
parport_control (int fd, unsigned char controlbits, int values)
{
	unsigned char val;

	if (ioctl (fd, PPIGCTRL, &val) == -1)
	{
		fprintf(stderr, "Parallel port PPIGCTRL");
		exit (1);
	}

	val &= ~controlbits;
	val |= values;

	if (ioctl (fd, PPISCTRL, &val) == -1)
	{
		fprintf(stderr, "Parallel port PPISCTRL");
		exit (1);
	}
}
#endif

/* open port and setup ppdev */
int
lp_init (int fd)
{
#ifdef HAVE_LINUX_PPDEV_H
	int mode;
#endif

#ifdef HAVE_LINUX_PPDEV_H
	mode = PARPORT_MODE_PCSPP;

	if (ioctl (fd, PPSETMODE, &mode) == -1)
	{
		fprintf(stderr, "Setting parallel port mode");
		close (fd);
		exit (1);
	}

	if (ioctl (fd, PPEXCL, NULL) == -1)
	{
		fprintf(stderr, "Parallel port %s is already in use", dev->desc);
		close (fd);
		exit (1);
	}
	if (ioctl (fd, PPCLAIM, NULL) == -1)
	{
		fprintf(stderr, "Claiming parallel port %s", dev->desc);
		debug ("HINT: did you unload the lp kernel module?");
		debug ("HINT: perhaps there is another cwdaemon running?");
		close (fd);
		exit (1);
	}

	/* Enable CW & PTT - /STROBE bit (pin 1) */
	parport_control (fd, PARPORT_CONTROL_STROBE, PARPORT_CONTROL_STROBE);
#endif
#ifdef HAVE_DEV_PPBUS_PPI_H
	parport_control (fd, STROBE, STROBE);
#endif
	lp_reset (fd);
	return 0;
}

/* release ppdev and close port */
int
lp_free (int fd)
{
#ifdef HAVE_LINUX_PPDEV_H
	lp_reset (fd);

	/* Disable CW & PTT - /STROBE bit (pin 1) */
	parport_control (fd, PARPORT_CONTROL_STROBE, 0);

	ioctl (fd, PPRELEASE);
#endif
#ifdef HAVE_DEV_PPBUS_PPI_H
	/* Disable CW & PTT - /STROBE bit (pin 1) */
	parport_control (fd, STROBE, 0);
#endif
	close (fd);
	return 0;
}

/* set to a known state */
int
lp_reset (int fd)
{
#if defined (HAVE_LINUX_PPDEV_H) || defined (HAVE_DEV_PPBUS_PPI_H)
	lp_ptt (fd, 0);
#endif
	return 0;
}

/* SSB PTT keying - /INIT bit (pin 16) (inverted) */
int
lp_ptt (int fd, int onoff)
{
#ifdef HAVE_LINUX_PPDEV_H
	if (onoff == 1)
		parport_control (fd, PARPORT_CONTROL_INIT,
				PARPORT_CONTROL_INIT);
	else
		parport_control (fd, PARPORT_CONTROL_INIT, 0);
#endif
#ifdef HAVE_DEV_PPBUS_PPI_H
	if (onoff == 1)
		parport_control (fd, nINIT,
				nINIT);
	else
		parport_control (fd, nINIT, 0);
#endif
	return 0;
}

/* XXX I am totally unsure of this, LPNAME should come from
 * the WSJT.INI instead but for now this should work -- db
 */
#ifdef BSD
#define LPNAME "lpt%d"
#else
#define LPNAME "lp%d"
#endif
#define LPNAME_SIZE (sizeof(LPNAME))

int
ptt_(int *nport, int *ntx, int *iptt)
{
  static int nopen=0;
  int fd;
  char s[LPNAME_SIZE];	

  if(*nport < 0) {
    *iptt=*ntx;
    return(0);
  }

  if(*ntx && (!nopen)) {
    snprintf(s, LPNAME_SIZE, LPNAME, (*nport) - 1);	/* Comport 1 == dev 0 */
    s[LPNAME_SIZE] = '\0';

    if ((fd = dev_is_parport(s)) < 0) {
      fprintf(stderr, "Can't use %s.", s);
      return(1);
    }

    if(*ntx && nopen) {
      lp_ptt(fd, 1);
      *iptt=1;
    }  else {
      lp_ptt(fd, 0);
      close(fd);
      *iptt=0;
      nopen=0;
    }
  }
  return(0);
}
#endif
