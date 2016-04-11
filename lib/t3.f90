program t3

  parameter (NBLK=3456,NZ=10*NBLK)
  real x0(NZ)
  real x1(NZ)

  twopi=8.0*atan(1.0)
  dphi=twopi*1000.0/12000.0
  phi=0.
  do i=1,NZ
     phi=phi+dphi
     x0(i)=sin(phi)
     if(mod(i,10007).eq.100) x0(i)=2.0
  enddo

  do j=1,10
     ib=j*NBLK
     ia=ib-NBLK+1
     call filter(x0(ia:ib),x1(ia:ib))
  enddo

  x1(1:NZ-NBLK)=x1(NBLK+1:NZ)
  do i=1,NZ-NBLK
     write(13,1001) i,x0(i),x1(i),x1(i)-x0(i)
1001 format(i6,3f13.9)
  enddo

end program t3

subroutine filter(x0,x1)

! Process time-domain data sequentially, optionally using a frequency-domain
! filter to alter the spectrum.

! NB: uses a sin^2 window with 50% overlap.

  parameter (NFFT=6912,NH=NFFT/2)
  real x0(0:NH-1)                         !Input samples
  real x1(0:NH-1)                         !Output samples (delayed by one block)
  real x0s(0:NH-1)                        !Saved upper half of input samples
  real x1s(0:NH-1)                        !Saved upper half of output samples
  real x(0:NFFT-1)                        !Work array
  real*4 w(0:NFFT-1)                      !Window function
  real f(0:NH)                            !Filter to be applied
  real*4 s(0:NH)                          !Average spectrum
  logical first
  complex cx(0:NH)                        !Complex frequency-domain work array
  equivalence (x,cx)
  data first/.true./
  save

  if(first) then
     pi=4.0*atan(1.0)
     do i=0,NFFT-1
        ww=sin(i*pi/NFFT)
        w(i)=ww*ww/NFFT
     enddo
     s=0.0
     f=1.0
     x0s=0.
     x1s=0.
     first=.false.
  endif

  x(0:NH-1)=x0s                             !Previous 2nd half to new 1st half
  x(NH:NFFT-1)=x0                           !New 2nd half
  x0s=x0                                    !Save the new 2nd half
  x=w*x                                     !Apply window
  call four2a(x,NFFT,1,-1,0)                !r2c FFT (to frequency domain)
  cx=f*cx
  call four2a(cx,NFFT,1,1,-1)               !c2r FFT (back to time domain)
  x1=x1s + x(0:NH-1)                        !Add previous segment's 2nd half
  x1s=x(NH:NFFT-1)                          !Save the new 2nd half

  return
end subroutine filter
