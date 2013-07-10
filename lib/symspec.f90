subroutine symspec(k,ntrperiod,nsps,ingain,slope,pxdb,s,df3,ihsym,npts8)

! Input:
!  k         pointer to the most recent new data
!  ntrperiod T/R sequence length, minutes
!  nsps      samples per symbol, at 12000 Hz
!  ndiskdat  0/1 to indicate if data from disk
!  nb        0/1 status of noise blanker (off/on)
!  nbslider  NB setting, 0-100

! Output:
!  pxdb      power (0-60 dB)
!  s()       current spectrum for waterfall display
!  ihsym     index number of this half-symbol (1-184)

! jt9com
!  ss()      JT9 symbol spectra at half-symbol steps
!  savg()    average spectra for waterfall display

  include 'constants.f90'
  real*4 w3(MAXFFT3)
  real*4 s(NSMAX)
  real*4 scale(NSMAX)
  real*4 ssum(NSMAX)
  real*4 xc(0:MAXFFT3-1)
  complex cx(0:MAXFFT3/2)
  integer*2 id2
  common/jt9com/ss(184,NSMAX),savg(NSMAX),id2(NMAX),nutc,ndiskdat,         &
       ntr,mousefqso,newdat,nfa,nfb,ntol,kin,nzhsym,nsynced,ndecoded
  data rms/999.0/,k0/99999999/,nfft3z/0/,slope0/0.0/
  equivalence (xc,cx)
  save

  if(ntrperiod.eq.-999) stop                   !Silence compiler warning
  nfft3=16384                                  !df=12000.0/16384 = 0.732422
  jstep=nsps/2                                 !Step size = half-symbol in id2()
  if(k.gt.NMAX) go to 900
  if(k.lt.2048) then                !(2048 was nfft3)  (Any need for this ???)
     ihsym=0
     go to 900                                 !Wait for enough samples to start
  endif

  if(nfft3.ne.nfft3z .or. slope.ne.slope0) then    !New nfft3, compute window
     pi=4.0*atan(1.0)
     do i=1,nfft3
        w3(i)=2.0*(sin(i*pi/nfft3))**2         !Window for nfft3 spectrum
     enddo
     nfft3z=nfft3
     nh=NSMAX/2
     do i=1,NSMAX
        x=slope*float(i)/nh - 1.0 + 2.6
        scale(i)=10.0**x
     enddo
     slope0=slope
  endif

  if(k.lt.k0) then                             !Start a new data block
     ja=0
     ssum=0.
     ihsym=0
     if(ndiskdat.eq.0) id2(k+1:)=0   !Needed to prevent "ghosts". Not sure why.
  endif
  gain=10.0**(0.05*ingain)
  sq=0.
  do i=k0+1,k
     x1=id2(i)
     sq=sq + x1*x1
  enddo
  sq=sq * gain**2
  rms=sqrt(sq/(k-k0))
  pxdb=0.
  if(rms.gt.0.0) pxdb=20.0*log10(rms)
  if(pxdb.gt.60.0) pxdb=60.0


  k0=k
  ja=ja+jstep                         !Index of first sample

  fac0=0.1
  do i=0,nfft3-1                      !Copy data into cx
     j=ja+i-(nfft3-1)
     xc(i)=0.
     if(j.ge.1) xc(i)=fac0*id2(j)
  enddo

  if(ihsym.lt.184) ihsym=ihsym+1

  xc(0:nfft3-1)=w3(1:nfft3)*xc(0:nfft3-1)    !Apply window w3
  call four2a(xc,nfft3,1,-1,0)               !Real-to-complex FFT

  n=min(184,ihsym)
  df3=12000.0/nfft3                   !JT9-1: 0.732 Hz = 0.42 * tone spacing
!  i0=nint(1000.0/df3)
  i0=0
  iz=min(NSMAX,nint(5000.0/df3))
  fac=(1.0/nfft3)**2
  do i=1,iz
     j=i0+i-1
     if(j.lt.0) j=j+nfft3
     sx=fac*(real(cx(j))**2 + aimag(cx(j))**2)
     ss(n,i)=sx
     ssum(i)=ssum(i) + sx
     s(i)=gain*sx
  enddo

!  s=0.05*s/ref
  s=scale*s
  savg=scale*ssum/ihsym

900 npts8=k/8

  return
end subroutine symspec
