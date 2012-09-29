subroutine symspecx(k,nsps,ndiskdat,nb,nbslider,pxdb,s,ihsym,   &
     nzap,slimit,lstrong)

!  k        pointer to the most recent new data
!  nsps     samples per symbol (at 12000 Hz)
!  ndiskdat 0/1 to indicate if data from disk
!  nb       0/1 status of noise blanker (off/on)
!  pxdb     power (0-60 dB)
!  s        spectrum for waterfall display
!  ihsym    index number of this half-symbol (1-322)
!  nzap     number of samples zero'ed by noise blanker

  parameter (NMAX=1800*12000)        !Total sample intervals per 30 minutes
  parameter (NSMAX=10000)             !Max length of saved spectra
  parameter (MAXFFT=262144)          !Max length of FFTs
  integer*2 id2
  real*8 ts,hsym
  real*8 fcenter
  common/jt8com/id2(NMAX),ss(184,NSMAX),savg(NSMAX),fcenter,nutc,junk(20)
  real*4 s(NSMAX)
  real x(MAXFFT)
  complex cx(0:MAXFFT/2)
  equivalence (x,cx)
  data rms/999.0/,k0/99999999/,ntrperiod0/0/
  save

  nfft=nsps
  hsym=nsps/2
  if(k.gt.NMAX) go to 999
  if(k.lt.nfft) then
     ihsym=0
     go to 999             !Wait for enough samples to start
  endif

  if(k.lt.k0) then
     ts=1.d0 - hsym
     savg=0.
     ihsym=0
     k1=0
     if(ndiskdat.eq.0) id2(k+1)=0.        !### Should not be needed ??? ###
  endif
  k0=k

  nzap=0
  sigmas=1.5*(10.0**(0.01*nbslider)) + 0.7
  peaklimit=sigmas*max(10.0,rms)
  faclim=3.0

  ts=ts+hsym
  ja=ts                               !Index of first sample
  jb=ja+nfft-1                        !Last sample

  i=0
  sq=0.
  do j=ja,jb                          !Copy data into cx, cy
     i=i+1
     x(i)=id2(j)
     sq=sq + x(i)*x(i)
  enddo
  rms=sqrt(sq/nfft)
  pxdb=0.
  if(rms.gt.1.0) pxdb=20.0*log10(rms)
  if(pxdb.gt.60.0) pxdb=60.0

  ihsym=ihsym+1
  call four2a(x,nfft,1,-1,0)          !Forward FFT of symbol length
  df=12000.0/nfft
  i0=nint(1000.0/df)
  nz=min(NSMAX,nfft/2)
!  rewind 71
  do i=1,nz
     sx=real(cx(i0+i))**2 + aimag(cx(i0+i))**2
     sx=1.e-8*sx
     s(i)=sx
     savg(i)=savg(i) + sx
     if(ihsym.le.184) ss(ihsym,i)=sx
!     write(71,3001) (i0+i-1)*df,savg(i),db(savg(i))
!3001 format(f12.6,2f12.3)
  enddo
!  flush(71)

999 return
end subroutine symspecx
