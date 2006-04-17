#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <inttypes.h>
#include <time.h>
#include <sys/time.h>
#include <fcntl.h>
#include <jack/types.h>
#include <jack/jack.h>
#include <string.h>

#define AUDIOBUFSIZE	4096
#define FRAMESPERBUFFER 1024

char rcv_buf[AUDIOBUFSIZE];	/* XXX grab one from upper app later --db */
char tx_buf[AUDIOBUFSIZE];	/* XXX grab one from upper app later --db */

/*
 * Lots of pieces stolen directly from jack simple_client.c
 */
jack_port_t *input_port;
jack_port_t *output_port;
jack_client_t *client;
void jack_read(void);
void jack_write(void);

/* a simple state machine for this client */
volatile enum {
	Init,
	Run,
	Exit
} client_state = Init;

extern void decode1_(int *iarg);

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

/**
 * The process callback for this JACK application is called in a
 * special realtime thread once for each audio cycle.
 *
 * This client follows a simple rule: when the JACK transport is
 * running, copy the input port to the output.  When it stops, exit.
 */
int
process (jack_nframes_t nframes, void *arg)
{
  jack_default_audio_sample_t *in, *out;
  jack_transport_state_t ts = jack_transport_query(client, NULL);
  int i;

  if (ts == JackTransportRolling) {

    if (client_state == Init)
      client_state = Run;
    printf("ZZZ nframes = %d\n", nframes);
    in = jack_port_get_buffer (input_port, nframes);
    /* First hack */
    memcpy (rcv_buf, in, AUDIOBUFSIZE);
    jack_read();

#if 0
    out = jack_port_get_buffer (output_port, nframes);
    memcpy (out, in,
	    sizeof (jack_default_audio_sample_t) * nframes);
#endif

  } else if (ts == JackTransportStopped) {
    
    if (client_state == Run)
      client_state = Exit;
  }

  return 0;      
}

/**
 * JACK calls this shutdown_callback if the server ever shuts down or
 * decides to disconnect the client.
 */
void
jack_shutdown (void *arg)
{
  return;
}

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
	       double tbuf[], int *ibuf, int *ndsec)
{
  pthread_t thread1,thread2;
  int iret1,iret2;
  int iarg1 = 1,iarg2 = 2;
  int32_t rate=*nfsample;
  double dnfs;
  const char **ports;
  const char *client_name;
  jack_options_t options = JackNullOption;
  jack_status_t status;

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

  /* open a client connection to the JACK server */

  client = jack_client_open ("wsjt", options, &status, NULL);
  if (client == NULL) {
    fprintf (stderr, "jack_client_open() failed, "
	     "status = 0x%2.0x\n", status);
    if (status & JackServerFailed) {
      fprintf (stderr, "Unable to connect to JACK server\n");
    }
    return(-1);
  }
  if (status & JackServerStarted) {
    fprintf (stderr, "JACK server started\n");
  }
  if (status & JackNameNotUnique) {
    client_name = jack_get_client_name(client);
    fprintf (stderr, "unique name `%s' assigned\n", client_name);
  }

  /* tell the JACK server to call `process()' whenever
   *  there is work to be done.
   */

  jack_set_process_callback (client, process, 0);

  /* tell the JACK server to call `jack_shutdown()' if
   * it ever shuts down, either entirely, or if it
   *  just decides to stop calling us.
   */

  jack_on_shutdown (client, jack_shutdown, 0);

  /* display the current sample rate. 
   */

  printf ("engine sample rate: %" PRIu32 "\n",
	  jack_get_sample_rate (client));

  /* create two ports */

  input_port = jack_port_register (client, "input",
				   JACK_DEFAULT_AUDIO_TYPE,
				   JackPortIsInput, 0);
  output_port = jack_port_register (client, "output",
				    JACK_DEFAULT_AUDIO_TYPE,
				    JackPortIsOutput, 0);

  if ((input_port == NULL) || (output_port == NULL)) {
    fprintf(stderr, "no more JACK ports available\n");
    /* ZZZ close jack above */
    return(-1);
  }

  /* Tell the JACK server that we are ready to roll.  Our
   * process() callback will start running now.
   */

  if (jack_activate (client)) {
    fprintf (stderr, "cannot activate client");
    /* ZZZ close jack above */
    return(-1);
  }

  /* Connect the ports.  You can't do this before the client is
   * activated, because we can't make connections to clients
   * that aren't running.  Note the confusing (but necessary)
   * orientation of the driver backend ports: playback ports are
   * "input" to the backend, and capture ports are "output" from
   * it.
   */

  ports = jack_get_ports (client, NULL, NULL,
			  JackPortIsPhysical|JackPortIsOutput);
  if (ports == NULL) {
    fprintf(stderr, "no physical capture ports\n");
    /* ZZZ close jack above */
    return(-1);
  }

  if (jack_connect (client, ports[0], jack_port_name (input_port))) {
    fprintf (stderr, "cannot connect input ports\n");
  }

  free (ports);
	
  ports = jack_get_ports (client, NULL, NULL,
			  JackPortIsPhysical|JackPortIsInput);
  if (ports == NULL) {
    fprintf(stderr, "no physical playback ports\n");
    /* ZZZ close jack above */
    return(-1);
  }

  if (jack_connect (client, jack_port_name (output_port), ports[0])) {
    fprintf (stderr, "cannot connect output ports\n");
  }

  free (ports);

  
  printf("Audio jack streams running normally.\n");
  printf("******************************************************************\n");

  printf("start_threads: creating thread for decode1\n");
  //  iret1 = pthread_create(&thread1, NULL,
  //			 (void *(*)(void *))oss_loop, &iarg1);
  // printf("start_threads: creating thread for decode1_\n");
  iret2 = pthread_create(&thread2, NULL,
			 (void *(*)(void *))decode1_,&iarg2);
/* keep running until the transport stops */

  while (client_state != Exit) {
    sleep (1);
  }

  jack_client_close (client);

  return(0);
}

/*
 * oss_loop
 *
 * inputs	- int pointer NOT USED
 * output	- none
 * side effects	-
 */

void
jack_read(void)
{
  struct timeval tv;
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

void
jack_write(void)
{
  int i;
  static int n=0;
  static int ic=0;
  struct timeval tv;
  static int n2=0;
  static int16_t *wptr;
  static int TxOKz=0;
  static int nsec=0;
  static double stime;

	/* Get System time */
	gettimeofday(&tv, NULL);
	stime = (double) tv.tv_sec + ((double)tv.tv_usec / 1000000.0) +
	  *(data.ndsec) * 0.1;
	*(data.Tsec) = stime;

	if(*(data.TxOK) && (!TxOKz))  {
	  n=nsec/(*(data.trperiod));
	  ic = (int)(stime - *(data.trperiod)*n) * data.nfs;
	  ic = ic % *(data.nwave);
	}

	TxOKz = *(data.TxOK);
	*(data.Transmitting) = *(data.TxOK);
	wptr = (int16_t *)tx_buf;		/* XXX */
	if(*(data.TxOK))  {
	  for(i=0 ; i<FRAMESPERBUFFER; i++ )  {
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

	if (write(data.fd_out, tx_buf, AUDIOBUFSIZE) < 0) {
	  fprintf(stderr, "Can't write to soundcard.\n");
	  return;
	}
	fivehztx_();                             /* Call fortran routine */
}
