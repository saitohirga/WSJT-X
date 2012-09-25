subroutine symspecx(k,ndiskdat,nb,nbslider,ntrperiod,pxdb,sdis,nkhz,   &
     ihsym,nzap,slimit,lstrong)

!  k        pointer to the most recent new data
!  ndiskdat 0/1 to indicate if data from disk
!  nb       0/1 status of noise blanker (off/on)
!  pxdb     power (0-60 dB)
!  sdis     spectrum for waterfall display
!  nkhz     integer kHz portion of center frequency, e.g., 125 for 144.125
!  ihsym    index number of this half-symbol (1-322)
!  nzap     number of samples zero'ed by noise blanker

  parameter (NSMAX=1800*12000)        !Total sample intervals per 30 minutes
  parameter (MAXFFT=32768)            !Max length of FFTs
  parameter (NDMAX=1800*375)
  integer*2 id2
  real*8 ts,hsym
  real*8 fcenter
  common/jt8com/id2(NSMAX),ss(184,MAXFFT),savg(MAXFFT),fcenter,nutc,junk(20), &
       cdat(NDMAX)
  real*4 sdis(MAXFFT),w(MAXFFT)
  complex cx(MAXFFT)
  complex cx00(MAXFFT)
  real x0(0:2047)
  complex cx0(0:1023),cx1(0:1023)
  logical*1 lstrong(0:1023)
  equivalence (x0,cx0)
  data rms/999.0/,k0/99999999/,ntrperiod0/0/
  save

  if(k.gt.NSMAX) go to 999
  if(k.lt.nfft) then
     ihsym=0
     go to 999             !Wait for enough samples to start
  endif
  if(ntrperiod.ne.ntrperiod0) then
     nfft=960
     if(ntrperiod.eq.120) nfft=2048
     if(ntrperiod.eq.300) nfft=5376
     if(ntrperiod.eq.600) nfft=10752
     if(ntrperiod.eq.1800) nfft=32768
     nsps=8*nfft
     hsym=0.5d0*nsps
     pi=4.0*atan(1.0)
     do i=1,nfft
        w(i)=(sin(i*pi/nfft))**2                          !Window
     enddo
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
  px=0.

  nwindow=2
  nfft2=1024
  kstep=nfft2
  if(nwindow.ne.0) kstep=nfft2/2
  nblks=(k-k1)/kstep
  do nblk=1,nblks
     j=k1+1
     do i=0,nfft2-1
        x0(i)=id2(j+i)
     enddo
     call timf2x(k,nfft2,ntrperiod,nwindow,nb,peaklimit,faclim,cx0,cx1,   &
          slimit,lstrong,px,nzap)
     do i=0,kstep-1
        cdat(j+i)=cx1(i)
     enddo
     k1=k1+kstep
  enddo

  npts=nfft                           !Samples used in each half-symbol FFT
  ts=ts+hsym
  ja=ts                               !Index of first sample
  jb=ja+npts-1                        !Last sample

  i=0
  fac=0.0002
  do j=ja,jb                          !Copy data into cx, cy
     i=i+1
     cx(i)=fac*cdat(j)
  enddo

  if(nzap/178.lt.50 .and. (ndiskdat.eq.0 .or. ihsym.lt.280)) then
     nsum=nblks*kstep - nzap
     if(nsum.le.0) nsum=1
     rms=sqrt(0.5*px/nsum)
  endif
  pxdb=0.
  if(rms.gt.1.0) pxdb=20.0*log10(rms)
  if(pxdb.gt.60.0) pxdb=60.0

  cx00=cx
  ihsym=ihsym+1
  cx=w*cx00                           !Apply window for 2nd forward FFT
  call four2a(cx,nfft,1,1,1)          !Second forward FFT (X)
  n=min(184,ihsym)
  do i=1,nfft
     sx=real(cx(i))**2 + aimag(cx(i))**2  
     ss(n,i)=sx
     sdis(i)=sx
     savg(i)=savg(i) + sx
  enddo

  nkhz=nint(1000.d0*(fcenter-int(fcenter)))
  if(fcenter.eq.0.d0) nkhz=125

999 return
end subroutine symspecx
