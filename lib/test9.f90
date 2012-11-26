subroutine test9(c0,npts8,nsps8)

  parameter (NMAX=128*864)
  complex c0(0:npts8-1)
  complex c1(0:NMAX-1)
  complex c2(0:4096-1)
  complex z
  real p(0:3300)
  include 'jt9sync.f90'

  c1(0:npts8-1)=c0                         !Copy c0 into c1
  c1(npts8:)=0.                            !Zero the rest of c1
  nfft1=NMAX                               !Forward FFT length
  call four2a(c1,nfft1,1,-1,1)             !Forward FFT
  
  ndown=54                                 !Downsample factor
  nfft2=nfft1/ndown                        !Backward FFT length
  nh2=nfft2/2
  fac=1.e-5
  c2(0:nh2)=fac*c1(0:nh2)
  c2(nh2+1:nh2+nh2-1)=fac*c1(nfft1-nh2+1:nfft1-1)
  call four2a(c2,nfft2,1,1,1)              !Backward FFT

  nspsd=nsps8/ndown
  nz=npts8/ndown

! Start of afc loop here: solve for DT, f0, f1, f2, (phi0) ?
  p=0.
  i0=5*nspsd
  do i=0,nz-1
     z=sum(c2(max(i-(nspsd-1),0):i))       !Integrate
     p(i0+i)=real(z)**2 + aimag(z)**2      !Symbol power at freq=0
! Option here for coherent processing ?
  enddo

  iz=85*nspsd
  lagmax=13*nspsd
  do lag=0,lagmax                          
     sum0=0.
     sum1=0.
     j=-nspsd
     do i=1,85
        j=j+nspsd
        if(isync(i).eq.1) then
           sum1=sum1+p(j+lag)
        else
           sum0=sum0+p(j+lag)
        endif
     enddo
     ss=(sum1/16.0)/(sum0/69.0) - 1.0
     write(52,3001) lag,ss
3001 format(i5,f12.3)
  enddo

  return
end subroutine test9
