subroutine wspr_fsk8_downsample(iwave,c)

! Input: i*2 data in iwave() at sample rate 12000 Hz
! Output: Complex data in c(), sampled at 12000/24=500 Hz

  include 'wspr_fsk8_params.f90'
  integer*2 iwave(NMAX)
  complex c(0:NMAXD-1)
  complex c1(0:NMAXD-1)
  complex cx(0:NMAX/2)
  real x(NMAX)
  equivalence (x,cx)

  df=12000.0/NMAX
  x=iwave
  call four2a(x,NMAX,1,-1,0)             !r2c FFT to freq domain
  i0=nint(1500.0/df)
  c1(0)=cx(i0)
  do i=1,NMAXD/2
     c1(i)=cx(i0+i)
     c1(NMAXD-i)=cx(i0-i)
  enddo
  c=c1/NMAXD
  call four2a(c,NMAXD,1,1,1)            !c2c FFT back to time domain
  
  return
end subroutine wspr_fsk8_downsample
