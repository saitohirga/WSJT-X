subroutine analytic(d,npts,nfft,s,c)

! Convert real data to analytic signal

  real d(npts)
  real s(npts)
  complex c(npts)

  nh=nfft/2
  fac=2.0/nfft
  c(1:npts)=fac*d(1:npts)
  c(npts+1:nfft)=0.
  call four2a(c,nfft,1,-1,1)               !Forward c2c FFT

  do i=1,nh
     s(i)=real(c(i))**2 + aimag(c(i))**2
  enddo

  c(1)=0.5*c(1)
  c(nh+2:nfft)=0.
  call four2a(c,nfft,1,1,1)                !Inverse c2c FFT

  return
end subroutine analytic
