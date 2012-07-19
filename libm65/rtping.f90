subroutine rtping(dat,k,cfile6,MinSigdB,MouseDF,ntol,mycall)

! Called from datasink() every 2048 sample intervals (approx 43 ms).
! Detects pings (signal level above MinSigdB).  When a ping ends, its
! MSK signal is synchronized and decoded.

  parameter (NSMAX=30*48000)
  parameter (NZMAX=703)          !703 = NSMAX/2048
  real dat(NSMAX)                !Raw audio data
  character*6 cfile6             !Time hhmmss at start of this Rx interval
  character*12 mycall
  real sig(NZMAX)                !Sq-law detected signal, sampled at 43 ms
  real sigdb(NZMAX)              !Signal in dB, sampled at 43 ms
  real tmp(NZMAX)
  logical inside,pingFound
  data k0/9999999/
  save

  if(k.lt.k0) then
     inside=.false.
     pingFound=.false.
     j0=0
     t1=0.
     width=0.
     peak=0.
     tpk=0.
     dt=1.0/48000.0
     kstep=2048
     sdt=dt*kstep
     wmin=0.043
  endif
  k0=k

  slim=MinSigdB
  snrlim=10.0**(0.1*slim) - 1.0
  sdown=10.0*log10(0.25*snrlim+1.0)

! Find signal power
  j=k/kstep
  sig(j)=dot_product(dat(k-kstep+1:k),dat(k-kstep+1:k))/kstep
  if(j.lt.20) return

! Determine baseline noise level
  if(mod(j,20).eq.0) call pctile (sig,tmp,j,50,base)
  sigdb(j)=db(sig(j)/base)                             ! (S+N)/N in dB

!  write(72,3001) j*sdt,base,sig(j),sigdb(j)
!3001 format(f10.3,3f12.6)

  if(sigdb(j).ge.slim .and. .not.inside) then
     j0=j                                       !Mark the start of a ping
     t1=j0*sdt
     inside=.true.
     peak=0.
  endif

  if(inside .and. sigdb(j).gt.peak) then
     peak=sigdb(j)                              !Save peak strength
     tpk=j*sdt                                  ! and time of peak
  endif
  
  if(inside .and. (sigdb(j).lt.sdown .or. j.eq.NZMAX)) then
     width=(j-j0)*sdt                           !Save ping width
     if(width.ge.wmin) pingFound=.true.
  endif
  if(.not.pingFound) return

! A ping was found!  Assemble a signal report:
  nwidth=0
  if(width.ge.0.04) nwidth=1
  if(width.ge.0.12) nwidth=2
  if(width.gt.1.00) nwidth=3
  nstrength=6
  if(peak.ge.11.0) nstrength=7
  if(peak.ge.17.0) nstrength=8
  if(peak.ge.23.0) nstrength=9
  nrpt=10*nwidth + nstrength

  mswidth=10*nint(100.0*width)
  i1=(t1-0.02)/dt
  if(i1.lt.1) i1=1
  iz=nint((width+0.02)/dt) + 1
  iz=min(iz,k+1-i1,2*48000)                   !Length of ping in samples

  call jtmsk(dat(i1),iz,cfile6,tpk,mswidth,int(peak),nrpt,      &
       nfreeze,DFTolerance,MouseDF,pick,mycall)

  pingFound=.false.
  inside=.false.

  return
end subroutine rtping
