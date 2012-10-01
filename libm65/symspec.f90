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
  real*4 s(NFFT),w(NFFT)
  complex z,zfac
  complex zsumx
  complex cx(NFFT)
  complex cx00(NFFT)
  complex cx0(0:1023),cx1(0:1023)
  logical*1 lstrong(0:1023)
  common/jt8com/id2(NMAX),ss(184,NSMAX),savg(NSMAX),fcenter,nutc,junk(20)
  data rms/999.0/,k0/99999999/,ntrperiod0/0/
  save

  nfft3=nsps
  hsym=nsps/2
  if(k.gt.NMAX) go to 999
  if(k.lt.nfft3) then
     ihsym=0
     go to 999             !Wait for enough samples to start
  endif
  if(k0.eq.99999999) then
     pi=4.0*atan(1.0)
     do i=1,nfft3
        w(i)=(sin(i*pi/nfft3))**2                     !Window for nfft3
     enddo
  endif

  if(k.lt.k0) then
     ts=1.d0 - hsym
     savg=0.
     ihsym=0
     k1=0
     if(ndiskdat.eq.0) id2(k+1:)=0.        !### Should not be needed ??? ###
  endif
  k0=k

  nzap=0
  sigmas=1.5*(10.0**(0.01*nbslider)) + 0.7
  peaklimit=sigmas*max(10.0,rms)
  faclim=3.0
  px=0.

  nwindow=2
!  nwindow=0                                    !### No windowing ###
  nfft1=1024
  kstep=nfft1
  if(nwindow.ne.0) kstep=nfft1/2
  nblks=(k-k1)/kstep
  do nblk=1,nblks
     j=k1+1
     do i=0,nfft1-1
        cx0(i)=cmplx(dd(1,j+i),dd(2,j+i))
     enddo
     call timf2x(k,nfft1,nwindow,nb,peaklimit,faclim,cx0,cx1,    &
          slimit,lstrong,px,nzap)

     do i=0,kstep-1
        dd(1,j+i)=real(cx1(i))
     enddo
     k1=k1+kstep
  enddo

  ts=ts+hsym
  ja=ts                               !Index of first sample
  jb=ja+nfft3-1                       !Last sample

  i=0
  fac=0.0002
  do j=ja,jb                          !Copy data into cx
     x1=dd(1,j)
     i=i+1
     cx(i)=fac*cmplx(x1,x2)
  enddo

  if(nzap/178.lt.50 .and. (ndiskdat.eq.0 .or. ihsym.lt.280)) then
     nsum=nblks*kstep - nzap
     if(nsum.le.0) nsum=1
     rmsx=sqrt(0.5*px/nsum)
     rms=rmsx
  endif
  pxdb=0.
  if(rmsx.gt.1.0) pxdb=20.0*log10(rmsx)
  if(pxdb.gt.60.0) pxdb=60.0

  cx00=cx

  ihsym=ihsym+1
  cx=w*cx00                           !Apply window for 2nd forward FFT
     
  call four2a(cx,nfft3,1,1,1)         !Second forward FFT (X)

  n=min(322,ihsym)
  do i=1,nfft3
     sx=real(cx(i))**2 + aimag(cx(i))**2  
     ss(1,n,i)=sx
     savg(1,i)=savg(1,i) + sx
     ssz5a(i)=sx
  enddo


999 return
end subroutine symspec
