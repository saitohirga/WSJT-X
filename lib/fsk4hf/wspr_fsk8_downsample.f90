subroutine wspr_fsk8_downsample(iwave,c)

! Input: i*2 data in iwave() at sample rate 12000 Hz
! Output: Complex data in c(), sampled at 4=500 Hz

  include 'wspr_fsk8_params.f90'
  parameter (NMAX=240*12000,NFFTD=NMAX/24)
  integer*2 iwave(NMAX)
  complex c(0:NZ-1)
  complex c1(0:NFFTD-1)
  complex cx(0:NMAX/2)
  real x(NMAX)
  equivalence (x,cx)

  df=12000.0/NMAX
  x=iwave
  call four2a(x,NMAX,1,-1,0)             !r2c FFT to freq domain
  i0=nint(1500.0/df)
  c1(0)=cx(i0)
  do i=1,NFFTD/2
     c1(i)=cx(i0+i)
     c1(NFFTD-i)=cx(i0-i)
  enddo
  c1=c1/NFFTD
  call four2a(c1,NFFTD,1,1,1)            !c2c FFT back to time domain
  c=c1(0:NZ-1)
  
  return
end subroutine wspr_fsk8_downsample
