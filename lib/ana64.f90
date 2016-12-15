subroutine ana64(dd,npts,c0)

  use timer_module, only: timer

  parameter (NMAX=60*12000)                  !Max size of raw data at 12000 Hz
  parameter (NSPS=3456)                      !Samples per symbol at 6000 Hz
  parameter (NSPC=7*NSPS)                    !Samples per Costas array
  real dd(NMAX)                              !Raw data
  complex c0(0:720000)                       !Complex spectrum of dd()
  save

  nfft1=672000
  nfft2=nfft1/2
  df1=12000.0/nfft1
  fac=2.0/nfft1
  c0(0:npts-1)=fac*dd(1:npts)
  c0(npts:nfft1)=0.
  call four2a(c0,nfft1,1,-1,1)             !Forward c2c FFT
  c0(nfft2/2+1:nfft2)=0.
  c0(0)=0.5*c0(0)
  call four2a(c0,nfft2,1,1,1)              !Inverse c2c FFT; c0 is analytic sig

  return
end subroutine ana64
