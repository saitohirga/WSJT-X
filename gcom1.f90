! Variable             Purpose                               Set in Thread
!---------------------------------------------------------------------------
integer NRXMAX         !Max length of Rx ring buffers
integer NTXMAX         !Max length of Tx waveform in samples
parameter(NRXMAX=2048*1024)
parameter(NTXMAX=150*11025)
real*8 tbuf            !Tsec at time of input callback          SoundIn
integer ntrbuf         !(obsolete?)
real*8 Tsec            !Present time                       SoundIn,SoundOut
real*8 rxdelay         !Delay between PTT=1 and Tx audio        SoundIn
real*8 txdelay         !Delay from end of Tx Audio and PTT=0    SoundOut
real*8 samfacin        !(Input sample rate)/11025               GUI
real*8 samfacout       !(Output sample rate)/11025              GUI
integer*2 y1           !Ring buffer for audio channel 0         SoundIn
integer*2 y2           !Ring buffer for audio channel 1         SoundIn
integer nmax           !Actual length of Rx ring buffers        GUI
integer iwrite         !Write pointer to Rx ring buffer         SoundIn
integer iread          !Read pointer to Rx ring buffer          GUI
integer*2 iwave        !Data for audio output                   SoundIn
integer nwave          !Number of samples in iwave              SoundIn
integer TxOK           !OK to transmit?                         SoundIn
!                       NB: TxOK=1 only in SoundIn; TxOK=0 also in GUI
integer Receiving      !Actually receiving?                     SoundIn
integer Transmitting   !Actually transmitting?                  SoundOut
integer TxFirst        !Transmit first?                         GUI
integer TRPeriod       !Tx or Rx period in seconds              GUI
integer ibuf           !Most recent input buffer#               SoundIn
integer ibuf0          !Buffer# at start of Rx sequence         SoundIn
real ave               !(why is this here?)                     GUI
real rms               !(why is this here?)                     GUI
integer ngo            !Set to 0 to terminate audio streams     GUI
integer level          !S-meter level, 0-100                    GUI
integer mute           !True means "don't transmit"             GUI
integer newdat         !New data available for waterfall?       GUI
integer ndsec          !Dsec in units of 0.1 s                  GUI
integer ndevin         !Device# for audio input                 GUI
integer ndevout        !Device# for audio output                GUI
integer nx             !x coordinate for waterfall pixmap       GUI
integer mfsample       !Measured sample rate, input             SoundIn
integer mfsample2      !Measured sample rate, output            SoundOut
integer ns0            !Time at last ALL.TXT date entry         Decoder

common/gcom1/Tbuf(1024),ntrbuf(1024),Tsec,rxdelay,txdelay,              &
     samfacin,samfacout,y1(NRXMAX),y2(NRXMAX),                          &
     nmax,iwrite,iread,iwave(NTXMAX),nwave,TxOK,Receiving,Transmitting, &
     TxFirst,TRPeriod,ibuf,ibuf0,ave,rms,ngo,level,mute,newdat,ndsec,   &
     ndevin,ndevout,nx,mfsample,mfsample2,ns0

!### volatile /gcom1/

