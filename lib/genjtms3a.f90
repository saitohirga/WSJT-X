subroutine genjtms3a(chansym,nsym,iwave,nwave)

  integer*1 chansym(nsym)
  integer*2 iwave(30*48000)
  real x(0:6191),x2(0:6191)
  complex c(0:3096),c2(0:6191)         !Could be 0:3096 ???
  equivalence (x,c),(x2,c2)

  do j=1,nsym                          !Define the baseband signal
     i0=24*(j-1)                       !24 samples per symbol
     x(i0:i0+23)=2*chansym(j)-1
  enddo

  nfft=24*nsym
  fac=1.0/nfft
  x(0:nfft-1)=fac*x(0:nfft-1)
  call four2a(x,nfft,1,-1,0)           !Forward r2c FFT

! Apply lowpass filter
  fc=1200.0
  bw=200.0
  df=48000.0/nfft
  nh=nfft/2
  c2=0.
  ib=2000.0/df

  do i=0,ib
     f=i*df
     g=1.0
     if(f.gt.fc) then
        xx=(f-fc)/bw
        g=exp(-xx*xx)
     endif
     c2(i)=g*c(i)
  enddo

  call four2a(c2,nfft,1,1,-1)            !Inverse c2r FFT

  nf0=nint(1500.0/df)
  f0=nf0*df
  twopi=8.0*atan(1.0)
  dphi=twopi*f0/48000.0
  phi=0.
  peak=0.
  sq=0.
  do i=0,nfft-1
     phi=phi+dphi
     if(phi.gt.twopi) phi=phi-twopi
     y=cos(phi)
     x2(i)=y*x2(i)
     sq=sq + x2(i)**2
     if(abs(x2(i)).gt.peak) peak=abs(x2(i))
  enddo
  rms=sqrt(sq/nfft)
!  print*,rms,peak,peak/rms

  fac=32767.0/peak
  do i=0,nfft-1
     iwave(i+1)=fac*x2(i)
  enddo
  nwave=30*48000
  nrpt=nwave/nfft
  do n=2,nrpt
     ib=n*nfft
     ia=ib-nfft+1
     iwave(ia:ib)=iwave(1:nfft)
  enddo

  return
end subroutine genjtms3a
