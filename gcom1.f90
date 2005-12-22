parameter(NRxMax=2048*1024)
parameter(NTxMax=150*11025)

real*8 Tsec                   !Present time
real*8 tbuf
real*8 rxdelay
real*8 txdelay
real*8 samfacin
real*8 samfacout
integer*2 y1                  !Rx audio samples (ring buffer)
integer*2 y2                  !WWVB or 1 PPS signal
integer iwrite                !Pointer to ring buffer
integer*2 iwave               !Tx data
integer nwave                 !Length of Tx data
integer TxOK                  !OK to transmit?
integer TxFirst               !Transmit first?
integer Receiving             !Actually receiving?
integer Transmitting          !Actually transmitting?
integer TRPeriod              !Tx or Rx period in seconds
integer level                 !S-meter level, 0-100
integer mute                  !True means "don't transmit"
integer ndsec                 !Dsec in units of 0.1 s
integer newdat                !True if waterfall should scroll
integer mfsample              !Measured sample rate, input
integer mfsample2             !Measured sample rate, output
character*8 cversion          !Program version

common/gcom1/Tbuf(1024),ntrbuf(1024),Tsec,rxdelay,txdelay,              &
     samfacin,samfacout,y1(NRxMax),y2(NRxMax),                          &
     nmax,iwrite,iread,iwave(NTXMAX),nwave,TxOK,Receiving,Transmitting, &
     TxFirst,TRPeriod,ibuf,ibuf0,ave,rms,ngo,level,mute,newdat,ndsec,   &
     ndevin,ndevout,nx,mfsample,mfsample2,ns0,                          &
     cversion

!### volatile /gcom1/

