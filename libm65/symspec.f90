subroutine symspecx(k,ntrperiod,nsps,ndiskdat,nb,nbslider,pxdb,s,ihsym,   &
     nzap,slimit,lstrong)

! Input:
!  k         pointer to the most recent new data
!  ntrperiod T/R sequence length, minutes
!  nsps      samples per symbol (12000 Hz)
!  ndiskdat  0/1 to indicate if data from disk
!  nb        0/1 status of noise blanker (off/on)
!  nbslider  NB setting, 0-100

! Output:
!  pxdb      power (0-60 dB)
!  s         spectrum for waterfall display
!  ihsym     index number of this half-symbol (1-322)
!  nzap      number of samples zero'ed by noise blanker
!  slimit    NB scale adjustment
!  lstrong   true if strong signal at this freq

  parameter (NMAX=1800*12000)        !Total sample intervals per 30 minutes
  parameter (NDMAX=1800*1500)        !Sample intervals at 1500 Hz rate
  parameter (NSMAX=22000)            !Max length of saved spectra
  parameter (NFFT1=1024)
  parameter (NFFT2=1024,NFFT2A=NFFT2/8)
  parameter (MAXFFT3=32768)
  real*4 s(NSMAX),w(NFFT1),w3(MAXFFT3)
  real*4 stmp(NFFT2/2)
  real*4 x0(NFFT1),x1(NFFT1)
  real*4 x2(NFFT2)
  complex cx2(0:NFFT2/2)
  complex cx2a(NFFT2A)
  complex z,zfac
  complex zsumx
  complex cx(MAXFFT3)
  complex cx00(NFFT1)
  complex cx0(0:1023),cx1(0:1023)
  logical*1 lstrong(0:1023)
  integer*2 id2
  complex c0
  common/jt8com/id2(NMAX),ss(184,NSMAX),savg(NSMAX),c0(NDMAX),nutc,junk(20)
  equivalence (x2,cx2)
  data rms/999.0/,k0/99999999/,ntrperiod0/0/,nfft3z/0/
  save

  if(ntrperiod.eq.1)  nfft3=1024
  if(ntrperiod.eq.2)  nfft3=2048
  if(ntrperiod.eq.5)  nfft3=6144
  if(ntrperiod.eq.10) nfft3=12288
  if(ntrperiod.eq.30) nfft3=32768

  jstep=nsps/16
  if(k.gt.NMAX) go to 999
  if(k.lt.nfft3) then
     ihsym=0
     go to 999                                 !Wait for enough samples to start
  endif
  if(nfft3.ne.nfft3z) then
     pi=4.0*atan(1.0)
     do i=1,nfft3
        w3(i)=(sin(i*pi/nfft3))**2             !Window for nfft3
     enddo
     stmp=0.
     nfft3z=nfft3
  endif

  if(k.lt.k0) then
     ja=-2*jstep
     savg=0.
     ihsym=0
     k1=0
     k8=0
     if(ndiskdat.eq.0) id2(k+1:)=0.        !### Should not be needed ??? ###
  endif
  k0=k

  nzap=0
  sigmas=1.5*(10.0**(0.01*nbslider)) + 0.7
  peaklimit=sigmas*max(10.0,rms)
  faclim=3.0
  px=0.
  df2=12000.0/NFFT2

!  nwindow=2
  nwindow=0                                    !### No windowing ###
  kstep1=NFFT1
  if(nwindow.ne.0) kstep1=NFFT1/2
  fac=1.0/(NFFT1*NFFT2)
  nblks=(k-k1)/kstep1
  do nblk=1,nblks
     do i=1,NFFT1
        x0(i)=fac*id2(k1+i)
     enddo
!     call timf2x(k,NFFT1,nwindow,nb,peaklimit,faclim,x0,x1,    &
!          slimit,lstrong,px,nzap)
     x1=x0                                     !###
     x2=x1
     call four2a(x2,NFFT2,1,-1,0)              !Second forward FFT, r2c

     i0=nint(1000.0/df2) + 1
     cx2a(1:NFFT2A/2)=cx2(i0:NFFT2A/2+i0-1)
     cx2a(NFFT2A/2+1:NFFT2A)=cx2(i0-1-NFFT2A/2:i0-1)
     call four2a(cx2a,NFFT2A,1,1,1)

     c0(k8+1:k8+NFFT2A)=cx2a

!###                                   Test for gliches at multiples of 128
!     if(k8.lt.1000) then
!        do i=k8+1,k8+NFFT2A
!           write(82,4002) i,c0(i)
!4002       format(i8,2e12.3)
!        enddo
!     endif
!###

     k1=k1+kstep1
     k8=k8+kstep1/8
  enddo

  ja=ja+jstep                         !Index of first sample
  if(ja.lt.0) go to 999
  do i=1,nfft3                          !Copy data into cx
     cx(i)=c0(ja+i)
  enddo

  pxdb=0.
  if(rmsx.gt.1.0) pxdb=20.0*log10(rmsx)
  if(pxdb.gt.60.0) pxdb=60.0

  ihsym=ihsym+1
  call four2a(cx,nfft3,1,-1,1)           !Third forward FFT (X)

  n=min(184,ihsym)
  df3=1500.0/nfft3
  iz=min(NSMAX,nint(1000.0/df3))
  do i=1,iz
     sx=real(cx(i))**2 + aimag(cx(i))**2  
     ss(n,i)=sx
     savg(i)=savg(i) + sx
     s(i)=sx
  enddo

  if(ihsym.eq.175) then
     do i=1,iz
        write(71,3001) i*df3,savg(i),10.0*log10(savg(i))
3001    format(f12.6,e12.3,f12.3)
     enddo
  endif

999 return
end subroutine symspecx
