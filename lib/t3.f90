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

  do i=1,NZ
     write(13,1001) i,x0(i),x1(i),x1(i)-x0(i)
1001 format(i6,3e12.3)
  enddo

end program t3

subroutine filter(x0,x1)

! Process time-domain data sequentially, optionally using 'refspec.dat' 
! to flatten the spectrum.

! NB: sin^2 window with 50% overlap; sin^2 + cos^2 = 1.0.

  parameter (NFFT=6912,NH=NFFT/2)
  real x0(0:NH-1)                         !Real input data
  real x1(0:NH-1)                         !Real output data
  real xov(0:NH-1)

  real x(0:NFFT-1)
  complex cx(0:NH)
  real*4 w(0:NFFT-1)
  real*4 s(0:NH)
  logical first
  equivalence (x,cx)
  data first/.true./
  save

  if(first) then
     pi=4.0*atan(1.0)
     do i=0,NFFT-1
        w(i)=(sin(i*pi/NFFT))**2
     enddo
     s=0.
     fac=1.0/NFFT
     first=.false.
     xov=0.
  endif

  x(:NH-1)=xov                              !Previous 2nd half to new 1st half
  x(NH:)=x0                                 !New 2nd half
  x=x*w                                     !Apply window
  call four2a(x,NFFT,1,-1,0)                !r2c FFT: to freq domain

! Apply filter to cx()

  call four2a(cx,NFFT,1,1,-1)               !c2r FFT: back to time domain

  x(0:NH-1)=x(0:NH-1)+xov(0:NH-1)           !Add previous segment's 2nd half

  x1=x

  return
end subroutine filter
