#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <inttypes.h>
#include <time.h>
#include <sys/time.h>
#include <fcntl.h>
#include <sys/soundcard.h>
#include <string.h>

#define AUDIOBUFSIZE	4096
#define FRAMESPERBUFFER 1024
#define TIMEOUT 1000L		/* select time out for audio device */

char rcv_buf[AUDIOBUFSIZE];	/* XXX grab one from upper app later --db */
char tx_buf[AUDIOBUFSIZE];	/* XXX grab one from upper app later --db */

#define DSP "/dev/dsp0.0"
#define MAXDSPNAME sizeof(DSP)+1	/* quick hack --db */
char dsp_in[MAXDSPNAME];		/* Both of these must be same length */
char dsp_out[MAXDSPNAME];

extern void decode1_(int *iarg);
void oss_loop(int *iarg);

/*
 * local state data referencing some gcom common fortran variables as well
 */
struct audio_data {
  int fd_in;		/* Audio fd in; used only locally in this function  */
  int fd_out;		/* Audio fd out; used only locally in this function */
  double *Tsec;		/* Present time                       SoundIn,SoundOut */
  double *tbuf;		/* Tsec at time of input callback          SoundIn  */
  int *iwrite;		/* Write pointer to Rx ring buffer         SoundIn  */
  int *ibuf;		/* Most recent input buffer#               SoundIn  */
  int *TxOK;		/* OK to transmit?                         SoundIn  */
  int *ndebug;		/* Write debugging info?                   GUI      */
  int *ndsec;		/* Dsec in units of 0.1 s                  GUI      */
  int *Transmitting;	/* Actually transmitting?                  SoundOut */
  int *nwave;		/* Number of samples in iwave              SoundIn  */
  int *nmode;		/* Which WSJT mode?                        GUI      */
  int *trperiod;	/* Tx or Rx period in seconds              GUI      */
  int nbuflen;
  int nfs;
  int16_t *y1;		/* Ring buffer for audio channel 0         SoundIn  */
  int16_t *y2;		/* Ring buffer for audio channel 1         SoundIn  */
  short  *iwave;
}data;

/*
 * start_threads()
 * inputs	- ndevin  device number for input
 *		- ndevout device number for output
 *		- y1 short int array for channel 0
 *		- y2 short int array for channel 1
 * 		- nmax
 *		- iwrite
 *		- iwave
 *		- nwave
 *		- rate 
 *		- NSPB
 *		- TRPeriod
 *		- TxOK
 *		- ndebug debug output or not?
 *		- Transmitting
 *		- Tsec
 *		- ngo
 *		- nmode
 *		- tbuf
 *		- ibuf
 *		- ndsec
 * output	- ?
 * side effects - Called from audio_init.f90 to start audio decode and
 *		  OSS thread.
 */

int
start_threads_(int *ndevin, int *ndevout, short y1[], short y2[],
	       int *nbuflen, int *iwrite, short iwave[],
	       int *nwave, int *nfsample, int *nsamperbuf,
	       int *TRPeriod, int *TxOK, int *ndebug,
	       int *Transmitting, double *Tsec, int *ngo, int *nmode,
	       double tbuf[], int *ibuf, int *ndsec,
	       char *PttPort, char *devin_name, char *devout_name)
{
  pthread_t thread1,thread2;
  int iret1,iret2;
  int iarg1 = 1,iarg2 = 2;
  int32_t rate=*nfsample;
  int samplesize;
  int format;
  int channels;
  double dnfs;
  int i;
  char *p;

  /* Remove space if present */
  p = strchr(devin_name, ' ');
  if(p != NULL)
    *p = '\0';

  /* If there is a '/' in the name assume it is /dev/name */
  p = strchr(devin_name, '/');
  if(p != NULL)
    snprintf(dsp_in, MAXDSPNAME, "%s", devin_name);	/* assume /dev/... */
  else
    snprintf(dsp_in, MAXDSPNAME, "/dev/%s", devin_name);

  dsp_in[MAXDSPNAME] = '\0';

  data.fd_in = open(dsp_in, O_RDWR, 0);

  if(data.fd_in < 0) { 
	fprintf(stderr, "Cannot open %s for input.\n", dsp_in);
	exit(-1);
  }

  data.fd_out = data.fd_in;
  strncpy(dsp_out, dsp_in, sizeof(dsp_out));
  dsp_out[sizeof(dsp_out)] = '\0';

  if(ioctl(data.fd_in, SNDCTL_DSP_SETDUPLEX, 0) < 0) {
    fprintf(stderr, "Cannot use %s for full duplex.\n", dsp_in);
    return(-1);
  }

  data.Tsec = Tsec;
  data.tbuf = tbuf;
  data.iwrite = iwrite;
  data.ibuf = ibuf;
  data.TxOK = TxOK;
  data.ndebug = ndebug;
  data.ndsec = ndsec;
  data.Transmitting = Transmitting;
  data.y1 = y1;
  data.y2 = y2;
  data.nbuflen = *nbuflen;
  data.nmode = nmode;
  data.nwave = nwave;
  data.iwave = iwave;
  data.nfs = *nfsample;
  data.trperiod = TRPeriod;

  dnfs=(double)*nfsample;

  channels = 2;
  if(ioctl (data.fd_in, SNDCTL_DSP_CHANNELS, &channels) == -1) {
	fprintf (stderr, "Unable to set 2 channels for input.\n");
	exit (-1);
  }

  if(channels != 2) {
    fprintf (stderr, "Unable to set 2 channels.\n");
    exit (-1);
  }

  format = AFMT_S16_NE;
  if(ioctl (data.fd_in, SNDCTL_DSP_SETFMT, &format) == -1) {
	fprintf (stderr, "Unable to set format for input.\n");
	exit (-1);
  }

  if(ioctl (data.fd_in, SNDCTL_DSP_SPEED, &rate) == -1) {
	fprintf (stderr, "Unable to set rate for input\n");
	exit (-1);
  }

  printf("Audio OSS streams running normally.\n");
  printf("******************************************************************\n");
  printf("Opened %s for input.\n", dsp_in);
  printf("Opened %s for output.\n", dsp_out);
  printf("Rate set = %d\n", rate);

  //  printf("start_threads: creating thread for oss_loop\n");
  iret1 = pthread_create(&thread1, NULL,
			 (void *(*)(void *))oss_loop, &iarg1);
  // printf("start_threads: creating thread for decode1_\n");
  iret2 = pthread_create(&thread2, NULL,
			 (void *(*)(void *))decode1_,&iarg2);
}

/*
 * oss_loop
 *
 * inputs	- int pointer NOT USED
 * output	- none
 * side effects	-
 */

void
oss_loop(int *iarg)
{
  fd_set readfds, writefds;
  int nfds = 0;
  struct timeval timeout = {0, 0};
  struct timeval tv;
  int nread;
  unsigned int i;
  static int n=0;
  static int n2=0;
  static int ia=0;
  static int ib=0;
  static int ic=0;
  static int16_t *in;
  static int16_t *wptr;
  static int TxOKz=0;
  static int ncall=0;
  static int nsec=0;
  static double stime;

  for (;;) {
    FD_ZERO(&readfds );
    FD_ZERO(&writefds );
    FD_SET(data.fd_in, &readfds);
    FD_SET(data.fd_out, &writefds);

    timeout.tv_usec = TIMEOUT;
    if(select(FD_SETSIZE, &readfds, &writefds, NULL, &timeout) > 0) {
      if(FD_ISSET(data.fd_in, &readfds)) {
	    nread = read (data.fd_in, rcv_buf, AUDIOBUFSIZE);
	    if(nread <= 0) {
	      fprintf(stderr, "Read error %d\n", nread);
	      return;
	    }
	    if(nread == AUDIOBUFSIZE) {
	      /* Get System time */
	      gettimeofday(&tv, NULL);
	      stime = (double) tv.tv_sec + ((double)tv.tv_usec / 1000000.0) +
		*(data.ndsec) * 0.1;
	      *(data.Tsec) = stime;

	      ncall++;

	      /* increment buffer pointers only if data available */
	      ia=*(data.iwrite);
	      ib=*(data.ibuf);
	      data.tbuf[ib-1] = stime;	/* convert to c index to store */
	      ib++;
	      if(ib>FRAMESPERBUFFER)
		ib=1; 
	      *(data.ibuf) = ib;
	      in = (int16_t *)rcv_buf;	/* XXX */
	      for(i=0; i<FRAMESPERBUFFER; i++) {
		data.y1[ia] = (*in++);
		data.y2[ia] = (*in++);
		ia++;
	      }

	      if(ia >= data.nbuflen)
		ia=0;  //Wrap buffer pointer if necessary
	      *(data.iwrite) = ia;            /* Save buffer pointer */
	      fivehz_();                      /* Call fortran routine */
	    }
      }
      if(FD_ISSET(data.fd_in, &writefds)) {
	/* Get System time */
	gettimeofday(&tv, NULL);
	stime = (double) tv.tv_sec + ((double)tv.tv_usec / 1000000.0) +
	  *(data.ndsec) * 0.1;
	*(data.Tsec) = stime;

	if(*(data.TxOK) && (!TxOKz)) {
	  nsec = (int)stime;
	  n = nsec / *(data.trperiod);
	  ic = (int)(stime - *(data.trperiod) * n) * data.nfs;
	  ic = ic % *(data.nwave);
	}

	TxOKz = *(data.TxOK);
	*(data.Transmitting) = *(data.TxOK);
	wptr = (int16_t *)tx_buf;		/* XXX */
	if(*(data.TxOK))  {
	  for(i=0 ; i<FRAMESPERBUFFER; i++)  {
	    n2 = data.iwave[ic];
	    addnoise_(&n2);
	    *wptr++ = n2;			/* left */
	    *wptr++ = n2;			/* right */
	    ic++;
	    if(ic >= *(data.nwave)) {
	      ic = ic % *(data.nwave);	/* Wrap buffer pointer if necessary */
	      if(*(data.nmode) == 2)
		*(data.TxOK) = 0;
	    }
	  }
	} else {
	  memset(tx_buf, 0, AUDIOBUFSIZE);
	}
	if(write(data.fd_out, tx_buf, AUDIOBUFSIZE) < 0) {
	  fprintf(stderr, "Can't write to soundcard.\n");
	  return;
	}
	fivehztx_();                             /* Call fortran routine */
      }
    }
  }
}
