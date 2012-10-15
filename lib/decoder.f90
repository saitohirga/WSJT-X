subroutine decoder(ntrSeconds)

! Decoder for JT9.  Can run stand-alone, reading data from *.wav files;
! or as the back end of wsjt-x, with data placed in a shared memory region.

! NB: For unknown reason, ***MUST*** be compiled by g95 with -O0 !!!

  parameter (NMAX=1800*12000)        !Total sample intervals per 30 minutes
  parameter (NDMAX=1800*1500)        !Sample intervals at 1500 Hz rate
  parameter (NSMAX=22000)            !Max length of saved spectra
  character*22 msg
  real*4 red(NSMAX)
  integer*1 i1SoftSymbols(207)
  integer*2 id2
  complex c0
  common/jt9com/id2(NMAX),ss(184,NSMAX),savg(NSMAX),c0(NDMAX),    &
       nutc,npts8,junk(20)


  ntrMinutes=ntrSeconds/60
  nfa=1000
  nfb=2000
  ntol=500
  mousedf=0
  mousefqso=1500
  newdat=1
  nb=0
  nbslider=100
  f0a=0.

  nsps=0
  if(ntrMinutes.eq.1)  nsps=6912
  if(ntrMinutes.eq.2)  then
     nsps=15360
     df3=0.7324219
  endif
  if(ntrMinutes.eq.5)  nsps=40960
  if(ntrMinutes.eq.10) nsps=82944
  if(ntrMinutes.eq.30) nsps=252000
  if(nsps.eq.0) stop 'Error: bad TRperiod'


! Now do the decoding
  nutc=nutc0
  nstandalone=1

  ntol=500
  nfqso=1500

! Get sync, approx freq
  call sync9(ss,tstep,f0a,df3,ntol,nfqso,sync,fpk,red)    
  fpk0=fpk

  call spec9(c0,npts8,nsps,f0a,fpk,xdt,i1SoftSymbols)
  call decode9(i1SoftSymbols,msg)

!  open(73,file='decoded.txt',status='unknown')
  iutc=0
  write(*,1010) iutc,xdt,1000.0+fpk,msg,sync,fpk0
  write(73,1010) iutc,xdt,1000.0+fpk,msg,sync,fpk0
1010 format(i4.4,f6.1,f7.1,2x,a22,2f9.1)
  flush(73)
!  close(13)

  return
end subroutine decoder
