subroutine wspr5_downsample(iwave,c)

! Input: i*2 data in iwave() at sample rate 12000 Hz
! Output: Complex data in c(), sampled at 400 Hz

  include 'wsprlf_params.f90'
  parameter (NMAX=300*12000,NFFT2=NMAX/30)
  integer*2 iwave(NMAX)
  complex c(0:NZ-1)
  complex c1(0:NFFT2-1)
  complex cx(0:NMAX/2)
  real x(NMAX)
  equivalence (x,cx)

  df=12000.0/NMAX
  x=iwave
  call four2a(x,NMAX,1,-1,0)             !r2c FFT to freq domain
  i0=nint(1500.0/df)
  c1(0)=cx(i0)
  do i=1,NFFT2/2
     c1(i)=cx(i0+i)
     c1(NFFT2-i)=cx(i0-i)
  enddo
  c1=c1/NFFT2
  call four2a(c1,NFFT2,1,1,1)            !c2c FFT back to time domain
  c=c1(0:NZ-1)
  
  return
end subroutine wspr5_downsample
