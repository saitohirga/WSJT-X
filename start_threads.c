#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <alsa/asoundlib.h>
#include <inttypes.h>
#include <time.h>

#if 0
#define ALSA_LOG
#define ALSA_LOG_BUFFERS
#endif
#define BUFFER_TIME               2000*1000


typedef struct alsa_driver_s {
	snd_pcm_t	*audio_fd;
	int		 capabilities;
	int		 open_mode;
	int		 has_pause_resume;
	int		 is_paused;
	int32_t		 output_sample_rate, input_sample_rate;
	double		 sample_rate_factor;
	uint32_t	 num_channels;
	uint32_t	 bits_per_sample;
	uint32_t	 bytes_per_frame;
	uint32_t	 bytes_in_buffer;      /* number of bytes writen to audio hardware   */
	int16_t		*app_buffer_y1;
	int16_t		*app_buffer_y2;
	int		*app_buffer_offset;
	int		 app_buffer_length;
	double		*Tsec;
	double		*tbuf;
	int		*ibuf;

	snd_pcm_uframes_t  buffer_size;
	snd_pcm_uframes_t  period_size;
	int32_t		 mmap; 
} alsa_driver_t;

alsa_driver_t alsa_driver_playback;
alsa_driver_t alsa_driver_capture;
void *alsa_buffers[2];

static snd_output_t *jcd_out;

/*
 * open the audio device for writing to
 */
static int ao_alsa_open(alsa_driver_t *this_gen, int32_t *input_rate, snd_pcm_stream_t direction ) {
  alsa_driver_t        *this = (alsa_driver_t *) this_gen;
  char                 *pcm_device;
  snd_pcm_hw_params_t  *params;
  snd_pcm_sw_params_t  *swparams;
  snd_pcm_access_mask_t *mask;
  snd_pcm_uframes_t     period_size_min; 
  snd_pcm_uframes_t     period_size_max; 
  snd_pcm_uframes_t     buffer_size_min;
  snd_pcm_uframes_t     buffer_size_max;
  snd_pcm_format_t      format;
  uint32_t              buffer_time=BUFFER_TIME;
  snd_pcm_uframes_t     buffer_time_to_size;
  int                   err, dir;
  int                 open_mode=1; /* NONBLOCK */
  /* int                   open_mode=0;  BLOCK */
  int32_t            rate=*input_rate;
  this->input_sample_rate=*input_rate;

  snd_pcm_hw_params_alloca(&params);
  snd_pcm_sw_params_alloca(&swparams);
  err = snd_output_stdio_attach(&jcd_out, stdout, 0);
  
  this->num_channels = 2;
  pcm_device="default";
#ifdef ALSA_LOG
  printf("audio_alsa_out: Audio Device name = %s\n",pcm_device);
  printf("audio_alsa_out: Number of channels = %d\n",this->num_channels);
#endif

  if (this->audio_fd) {
    printf("audio_alsa_out:Already open...WHY!");
    snd_pcm_close (this->audio_fd);
    this->audio_fd = NULL;
  }

  this->bytes_in_buffer        = 0;
  /*
   * open audio device
   */
  err=snd_pcm_open(&this->audio_fd, pcm_device, direction, open_mode);      
  if(err <0 ) {                                                           
    printf ("audio_alsa_out: snd_pcm_open() of %s failed: %s\n", pcm_device, snd_strerror(err));               
    printf ("audio_alsa_out: >>> check if another program already uses PCM <<<\n");
    return 0;
  }
  /* printf ("audio_alsa_out: snd_pcm_open() opened %s\n", pcm_device); */ 
  /* We wanted non blocking open but now put it back to normal */
  //snd_pcm_nonblock(this->audio_fd, 0);
  snd_pcm_nonblock(this->audio_fd, 1);
  /*
   * configure audio device
   */
  err = snd_pcm_hw_params_any(this->audio_fd, params);
  if (err < 0) {
    printf ("audio_alsa_out: broken configuration for this PCM: no configurations available: %s\n"),
	     snd_strerror(err);
    goto close;
  }
  /* set interleaved access */
  if (this->mmap != 0) {
    mask = alloca(snd_pcm_access_mask_sizeof());
    snd_pcm_access_mask_none(mask);
    snd_pcm_access_mask_set(mask, SND_PCM_ACCESS_MMAP_INTERLEAVED);
    snd_pcm_access_mask_set(mask, SND_PCM_ACCESS_MMAP_NONINTERLEAVED);
    snd_pcm_access_mask_set(mask, SND_PCM_ACCESS_MMAP_COMPLEX);
    err = snd_pcm_hw_params_set_access_mask(this->audio_fd, params, mask);
    if (err < 0) {
      printf ( "audio_alsa_out: mmap not availiable, falling back to compatiblity mode\n");
      this->mmap=0;
      err = snd_pcm_hw_params_set_access(this->audio_fd, params,
                                     SND_PCM_ACCESS_RW_NONINTERLEAVED);
    }
  } else {
    err = snd_pcm_hw_params_set_access(this->audio_fd, params,
                                     SND_PCM_ACCESS_RW_NONINTERLEAVED);
  }
      
  if (err < 0) {
    printf ( "audio_alsa_out: access type not available: %s\n", snd_strerror(err));
    goto close;
  }
  /* set the sample format S16 */
  /* ALSA automatically appends _LE or _BE depending on the CPU */
  format = SND_PCM_FORMAT_S16;
  err = snd_pcm_hw_params_set_format(this->audio_fd, params, format );
  if (err < 0) {
    printf ( "audio_alsa_out: sample format non available: %s\n", snd_strerror(err));
    goto close;
  }
  /* set the number of channels */
  err = snd_pcm_hw_params_set_channels(this->audio_fd, params, this->num_channels);
  if (err < 0) {
    printf ( "audio_alsa_out: Cannot set number of channels to %d (err=%d:%s)\n", 
	     this->num_channels, err, snd_strerror(err));
    goto close;
  }
#if SND_LIB_VERSION >= 0x010009
  /* Restrict a configuration space to contain only real hardware rates */
  err = snd_pcm_hw_params_set_rate_resample(this->audio_fd, params, 0);
#endif
  /* set the stream rate [Hz] */
  dir=0;
  err = snd_pcm_hw_params_set_rate_near(this->audio_fd, params, &rate, &dir);
  if (err < 0) {
    printf ( "audio_alsa_out: rate not available: %s\n", snd_strerror(err));
    goto close;
  }
  this->output_sample_rate = (uint32_t)rate;
  if (this->input_sample_rate != this->output_sample_rate) {
    printf ( "audio_alsa_out: audio rate : %d requested, %d provided by device/sec\n",
	     this->input_sample_rate, this->output_sample_rate);
  }
  buffer_time_to_size = ( (uint64_t)buffer_time * rate) / 1000000;
  err = snd_pcm_hw_params_get_buffer_size_min(params, &buffer_size_min);
  err = snd_pcm_hw_params_get_buffer_size_max(params, &buffer_size_max);
  dir=0;
  err = snd_pcm_hw_params_get_period_size_min(params, &period_size_min,&dir);
  dir=0;
  err = snd_pcm_hw_params_get_period_size_max(params, &period_size_max,&dir);
#ifdef ALSA_LOG_BUFFERS
  printf("Buffer size range from %lu to %lu\n",buffer_size_min, buffer_size_max);
  printf("Period size range from %lu to %lu\n",period_size_min, period_size_max);
  printf("Buffer time size %lu\n",buffer_time_to_size);
#endif
  this->buffer_size = buffer_time_to_size;
  if (buffer_size_max < this->buffer_size) this->buffer_size = buffer_size_max;
  if (buffer_size_min > this->buffer_size) this->buffer_size = buffer_size_min;
  this->period_size=this->buffer_size/8;
  this->buffer_size = this->period_size*8;
#ifdef ALSA_LOG_BUFFERS
  printf("To choose buffer_size = %ld\n",this->buffer_size);
  printf("To choose period_size = %ld\n",this->period_size);
#endif

#if 0
  /* Set period to buffer size ratios at 8 periods to 1 buffer */
  dir=-1;
  periods=8;
  err = snd_pcm_hw_params_set_periods_near(this->audio_fd, params, &periods ,&dir);
  if (err < 0) {
    xprintf (this->class->xine, XINE_VERBOSITY_DEBUG, 
	     "audio_alsa_out: unable to set any periods: %s\n", snd_strerror(err));
    goto close;
  }
  /* set the ring-buffer time [us] (large enough for x us|y samples ...) */
  dir=0;
  err = snd_pcm_hw_params_set_buffer_time_near(this->audio_fd, params, &buffer_time, &dir);
  if (err < 0) {
    xprintf (this->class->xine, XINE_VERBOSITY_DEBUG, 
	     "audio_alsa_out: buffer time not available: %s\n", snd_strerror(err));
    goto close;
  }
#endif
#if 1
  /* set the period time [us] (interrupt every x us|y samples ...) */
  dir=0;
  err = snd_pcm_hw_params_set_period_size_near(this->audio_fd, params, &(this->period_size), &dir);
  if (err < 0) {
    printf ( "audio_alsa_out: period time not available: %s\n", snd_strerror(err));
    goto close;
  }
#endif
  dir=0;
  err = snd_pcm_hw_params_get_period_size(params, &(this->period_size), &dir);

  dir=0;
  err = snd_pcm_hw_params_set_buffer_size_near(this->audio_fd, params, &(this->buffer_size));
  if (err < 0) {
    printf ( "audio_alsa_out: buffer time not available: %s\n", snd_strerror(err));
    goto close;
  }
  err = snd_pcm_hw_params_get_buffer_size(params, &(this->buffer_size));
#ifdef ALSA_LOG_BUFFERS
  printf("was set period_size = %ld\n",this->period_size);
  printf("was set buffer_size = %ld\n",this->buffer_size);
#endif
  if (2*this->period_size > this->buffer_size) {
    printf ( "audio_alsa_out: buffer to small, could not use\n");
    goto close;
  }
  
  /* write the parameters to device */
  err = snd_pcm_hw_params(this->audio_fd, params);
  if (err < 0) {
    printf ( "audio_alsa_out: pcm hw_params failed: %s\n", snd_strerror(err));
    goto close;
  }
  /* Check for pause/resume support */
  this->has_pause_resume = ( snd_pcm_hw_params_can_pause (params)
			    && snd_pcm_hw_params_can_resume (params) );
  printf( "audio_alsa_out:open pause_resume=%d\n", this->has_pause_resume);
  this->sample_rate_factor = (double) this->output_sample_rate / (double) this->input_sample_rate;
  this->bytes_per_frame = snd_pcm_frames_to_bytes (this->audio_fd, 1);
  /*
   * audio buffer size handling
   */
  /* Copy current parameters into swparams */
  err = snd_pcm_sw_params_current(this->audio_fd, swparams);
  if (err < 0) {
    printf ( "audio_alsa_out: Unable to determine current swparams: %s\n", snd_strerror(err));
    goto close;
  }
  /* align all transfers to 1 sample */
  err = snd_pcm_sw_params_set_xfer_align(this->audio_fd, swparams, 1);
  if (err < 0) {
    printf ( "audio_alsa_out: Unable to set transfer alignment: %s\n", snd_strerror(err));
    goto close;
  }
  /* allow the transfer when at least period_size samples can be processed */
  err = snd_pcm_sw_params_set_avail_min(this->audio_fd, swparams, this->period_size);
  if (err < 0) {
    printf ( "audio_alsa_out: Unable to set available min: %s\n", snd_strerror(err));
    goto close;
  }
  if (direction == SND_PCM_STREAM_PLAYBACK) {
  	/* start the transfer when the buffer contains at least period_size samples */
	err = snd_pcm_sw_params_set_start_threshold(this->audio_fd, swparams, 0);
  } else {
	err = snd_pcm_sw_params_set_start_threshold(this->audio_fd, swparams, -1);
  }
  if (err < 0) {
    printf ( "audio_alsa_out: Unable to set start threshold: %s\n", snd_strerror(err));
    goto close;
  }

  if (direction == SND_PCM_STREAM_PLAYBACK) {
        /* never stop the transfer, even on xruns */
  	err = snd_pcm_sw_params_set_stop_threshold(this->audio_fd, swparams, 0);
  } else {
  	err = snd_pcm_sw_params_set_stop_threshold(this->audio_fd, swparams, this->buffer_size);
  }
  if (err < 0) {
    printf ( "audio_alsa_out: Unable to set stop threshold: %s\n", snd_strerror(err));
    goto close;
  }

  /* Install swparams into current parameters */
  err = snd_pcm_sw_params(this->audio_fd, swparams);
  if (err < 0) {
    printf ( "audio_alsa_out: Unable to set swparams: %s\n", snd_strerror(err));
    goto close;
  }
#ifdef ALSA_LOG
  snd_pcm_dump_setup(this->audio_fd, jcd_out); 
  snd_pcm_sw_params_dump(swparams, jcd_out);
#endif
  
  return this->output_sample_rate;

close:
  snd_pcm_close (this->audio_fd);
  this->audio_fd=NULL;
  return 0;
}

int playback_callback(alsa_driver_t *alsa_driver_playback) {
	alsa_driver_t *this = alsa_driver_playback;
	printf("playback callback\n");
	//snd_pcm_writen(this->audio_fd, alsa_buffers, this->period_size);
  	//fivehztx_();                             //Call fortran routine
}

int capture_callback(alsa_driver_t *alsa_driver_capture) {
	alsa_driver_t *this = alsa_driver_capture;
	int result;
	struct timeval tv;
	double stime;
	int ib;
#ifdef ALSA_LOG
	printf("capture callback %d samples\n", this->period_size);
#endif
#ifdef ALSA_LOG
	snd_pcm_status_t *pcm_stat;
	snd_pcm_status_alloca(&pcm_stat);
	snd_pcm_status(this->audio_fd, pcm_stat);
        snd_pcm_status_dump(pcm_stat, jcd_out);
#endif
	gettimeofday(&tv, NULL);
	stime = (double) tv.tv_sec + ((double)tv.tv_usec / 1000.0);
	ib=*(this->ibuf);
	this->tbuf[ib++]=stime;
	if(ib>=1024) ib=0;
	*(this->ibuf)=ib;

	alsa_buffers[0]=this->app_buffer_y1 + *(this->app_buffer_offset);
	alsa_buffers[1]=this->app_buffer_y2 + *(this->app_buffer_offset);
	result = snd_pcm_readn(this->audio_fd, alsa_buffers, this->period_size);
	*(this->app_buffer_offset) += this->period_size;
	if ( *this->app_buffer_offset >= this->app_buffer_length )
		this->app_buffer_length=0;  /* FIXME: implement proper wrapping */
#ifdef ALSA_LOG
	printf("result=%d\n",result);
	snd_pcm_status(this->audio_fd, pcm_stat);
        snd_pcm_status_dump(pcm_stat, jcd_out);
#endif
	fivehz_();                             //Call fortran routine
}

int capture_xrun(alsa_driver_t *alsa_driver_capture) {
	alsa_driver_t *this = alsa_driver_capture;
	snd_pcm_status_t *pcm_stat;
	snd_pcm_status_alloca(&pcm_stat);
	printf("capture xrun\n");
	snd_pcm_status(this->audio_fd, pcm_stat);
        snd_pcm_status_dump(pcm_stat, jcd_out);
}

void ao_alsa_loop(void *iarg) {
	int playback_nfds;
	int capture_nfds;
	struct pollfd *pfd;
	int nfds;
	int capture_index;
	unsigned short playback_revents;
	unsigned short capture_revents;
	playback_nfds = snd_pcm_poll_descriptors_count (
				alsa_driver_playback.audio_fd);
	capture_nfds = snd_pcm_poll_descriptors_count (
				alsa_driver_capture.audio_fd);
	pfd = (struct pollfd *) malloc (sizeof (struct pollfd) * 
		(playback_nfds + capture_nfds));
	
	nfds=0;	
#if 0
	snd_pcm_poll_descriptors (alsa_driver_playback.audio_fd,
		&pfd[0],
		playback_nfds);
	nfds += playback_nfds;
#endif
	snd_pcm_poll_descriptors (alsa_driver_capture.audio_fd,
		&pfd[nfds],
		capture_nfds);
	capture_index = nfds;
	nfds += capture_nfds;
	while(1) {
		if (poll (pfd, nfds, 100000) < 0) {
			printf("poll failed\n");
			return;
		}
		//snd_pcm_poll_descriptors_revents(alsa_driver_playback.audio_fd, &pfd[0], playback_nfds, &playback_revents);
		snd_pcm_poll_descriptors_revents(alsa_driver_capture.audio_fd, &pfd[capture_index], capture_nfds, &capture_revents);
		//if ((playback_revents & POLLERR) || ((capture_revents) & POLLERR)) {
		if (((capture_revents) & POLLERR)) {
			printf("pollerr\n");
			capture_xrun(&alsa_driver_capture);
			return;
		}
#if 0
		if (playback_revents & POLLOUT) {
			playback_callback(&alsa_driver_playback);
		}
#endif
		if (capture_revents & POLLIN) {
			capture_callback(&alsa_driver_capture);
		}
	}
		
	return;
}


extern void decode1_(int *iarg);
int start_threads_(int *ndevin, int *ndevout, short y1[], short y2[],
	int *nbuflen, int *iwrite, short iwave[],
	int *nwave, int *nfsample, int *nsamperbuf,
	int *TRPeriod, int *TxOK, int *ndebug,
	int *Transmitting, double *Tsec, int *ngo, int *nmode,
	double tbuf[], int *ibuf, int *ndsec)
{
  pthread_t thread1,thread2;
  int iret1,iret2;
  int iarg1=1,iarg2=2;
  //int32_t rate=11025;
  int32_t rate=*nfsample;
  alsa_driver_capture.app_buffer_y1=y1;
  alsa_driver_capture.app_buffer_y2=y2;
  alsa_driver_capture.app_buffer_offset=iwrite;
  alsa_driver_capture.app_buffer_length=*nsamperbuf;
  alsa_driver_capture.Tsec=Tsec;
  alsa_driver_capture.tbuf=tbuf;
  alsa_driver_capture.ibuf=ibuf;

  printf("start threads called\n");
  iret1 = pthread_create(&thread1,NULL,decode1_,&iarg1);
/* Open audio card. */
  ao_alsa_open(&alsa_driver_playback, &rate, SND_PCM_STREAM_PLAYBACK);
  ao_alsa_open(&alsa_driver_capture, &rate, SND_PCM_STREAM_CAPTURE);

/*
 * Start audio io thread
 */
  iret2 = pthread_create(&thread2, NULL, ao_alsa_loop, NULL);
  snd_pcm_prepare(alsa_driver_capture.audio_fd);
  snd_pcm_start(alsa_driver_capture.audio_fd);

 /* snd_pcm_start */
  //iret2 = pthread_create(&thread2,NULL,a2d_,&iarg2);

}
