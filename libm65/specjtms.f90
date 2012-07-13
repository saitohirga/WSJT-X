subroutine specjtms(k,px,pxsmo,spk0,f0)

! Compute noise level and 2D spectra, for GUI display.

  parameter (NSMAX=30*48000)
  parameter (MAXFFT=8192)
  integer*2 id
  real x(MAXFFT)
  complex cx(MAXFFT),cx2(MAXFFT)
  logical first
  common/mscom/id(1440000),s1(215),s2(215),kin,ndiskdat,kline
  data first/.true./
  save
 
  if(first) then
     pi=4.0*atan(1.0)
     twopi=2.0*pi
     kstep=2048
     first=.false.
     sqsmo=0.
  endif

  t=k/48000.0
  nfft=4096
  df=48000.0/nfft
  nh=nfft/2
  ib=k
  ia=k-kstep+1
  i0=k-nfft+1
  sq=0.
  do i=ia,ib
     d=id(i)
     sq=sq + d*d
  enddo
  sq=sq/2048.0
  sqsmo=0.95*sqsmo + 0.05*sq
  rms=sqrt(sq)
  px=db(sq) - 23.0
  pxsmo=db(sqsmo) - 23.0

  do i=i0,ia-1
     d=id(i)
     sq=sq + d*d
  enddo
  sq0=sq
!  write(13,1010) t,rms,sq,px,pxsmo
!1010 format(5f12.3)
  if(k.lt.nfft) return


  x(1:nfft)=id(i0:ib)
  fac=0.002/nfft
  cx=fac*x
  call four2a(cx,nfft,1,-1,1)                    !Forward c2c FFT

  iz=nint(2500.0/df)

  do i=1,iz                                      !Save spectrum for plot
     s1(i)=real(cx(i+1))**2 + aimag(cx(i+1))**2
  enddo

  cx(1)=0.5*cx(1)
  cx(nh+2:nfft)=0.
  call four2a(cx,nfft,1,1,1)                     !Inverse c2c FFT

  cx2(1:nfft)=cx(1:nfft)*cx(1:nfft)
  cx2(nfft+1:)=0.0

  nfft=8192
  df=48000.0/nfft
  
  call four2a(cx2,nfft,1,-1,1)                   !Forward c2c FFT of cx2

  j0=nint(2.0*1428.57/df)
  ja=j0-107
  jb=j0+107
  do j=ja,jb
     s2(j-ja+1)=1.e-4*(real(cx2(j))**2 + aimag(cx2(j))**2)
  enddo

  spk0=0.
  fac=(5e8/sq0)**2
  s2=fac*s2
  do j=1,215
     if(s2(j).gt.spk0) then
        spk0=s2(j)
        f=(j+ja-1)*df
        f0=0.5*(f-3000.0)
        phi0=0.5*atan2(aimag(cx2(j)),real(cx2(j)))
     endif
  enddo

  spk0=0.5*db(spk0) - 7.0
  kline=k/2048
!  write(14,3001) k/2048,spk0,f0,phi0
!3001 format(i8,3f12.3)
!  call flush(14)

  return
end subroutine specjtms
