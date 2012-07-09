subroutine specjtms(k)

! Starting code for a JTMS3 decoder.

  parameter (NSMAX=30*48000)
  parameter (NFFT=8192,NH=NFFT/2)
  integer*2 id
  real x(NFFT),w(NFFT)
  complex cx(NFFT),cx2(NFFT)
  complex covx(NH)
  real s1a(NH),s2a(580)
  logical first,window
  common/mscom/id(1440000),s1(215,703),s2(215,703)
  data first/.true./
  save

  if(first) then
     pi=4.0*atan(1.0)
     do i=1,nfft
        w(i)=(sin(i*pi/nfft))**2
     enddo
     df=48000.0/nfft
     ja=nint(2600.0)/df
     jb=nint(3400.0)/df
     iz=3000.0/df
     covx=0.
     window=.false.
     first=.false.
  endif

  ib=k
  ia=k-4095
  i0=ib-8191
  sq=0.
  do i=ia,ib
     sq=sq + (0.001*id(i))**2
  enddo
  write(13,1010) t,sq,db(sq)
1010 format(3f12.3)
  if(k.lt.8192) return

  x(1:nfft)=0.001*id(i0:ib)
!  call analytic(x,nfft,nfft,s,cx)

  fac=2.0/nfft
  cx=fac*x
  if(window) cx=w*cx
  call four2a(cx,nfft,1,-1,1)                    !Forward c2c FFT

  do i=1,iz                                      !Save spectrum for plot
     s1a(i)=real(cx(i+1))**2 + aimag(cx(i+1))**2
  enddo

  cx(1)=0.5*cx(1)
  cx(nh+2:nfft)=0.
  call four2a(cx,nfft,1,1,1)                     !Inverse c2c FFT
  if(window) then
     cx(1:nh)=cx(1:nh)+covx(1:nh)               !Add previous segment's 2nd half
     covx(1:nh)=cx(nh+1:nfft)                    !Save 2nd half
  endif

  t=k/48000.0
  cx2=cx*cx
  call four2a(cx2,nfft,1,-1,1)                   !Forward c2c FFT of cx2

  spk0=0.
  do j=ja,jb
     sq=1.e-6*(real(cx2(j))**2 + aimag(cx2(j))**2)
     s2a(j)=sq
     f=(j-1)*df
     if(sq.gt.spk0) then
        spk0=sq
        f0=0.5*(f-3000.0)
        phi0=atan2(aimag(cx2(j)),real(cx2(j)))
     endif
     write(15,1020) (j-1)*df,sq
1020 format(f10.3,f12.3)
  enddo

  slimit=1.5
  if(spk0.gt.slimit) then
     write(*,1030) t,f0,phi0,spk0
1030 format('t:',f6.2,'   f0:',f7.1,'   phi0:',f6.2,'   spk0:',f8.1)
     do i=1,iz
        write(16,1040) i*df,s1a(i),db(s1a(i))
1040    format(3f12.3)
     enddo
     do j=ja,jb
        f=(j-1)*df
        f0a=0.5*(f-3000.0)
        write(17,1050) f0a,s2a(j)
1050    format(2f12.3)
     enddo
  endif

end subroutine specjtms
