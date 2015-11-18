subroutine analytic(d,npts,nfft,c)

! Convert real data to analytic signal

  parameter (NFFTMAX=1024*1024)
  real d(npts)
  real h(NFFTMAX/2)
  complex c(NFFTMAX)
  data nfft0/0/
  save nfft0,h

  df=12000.0/nfft
  nh=nfft/2
  if(nfft.ne.nfft0) then
     t=1.0/2000.0
     beta=0.6
     pi=4.0*atan(1.0)
     do i=1,nh+1
        ff=(i-1)*df
        f=ff-1500.0
        h(i)=0.
        if(abs(f).le.(1-beta)/(2*t)) h(i)=1.0
        if(abs(f).gt.(1-beta)/(2*t) .and. abs(f).le.(1+beta)/(2*t)) then
           h(i)=0.5*(1+cos((pi*t/beta )*(abs(f)-(1-beta)/(2*t))))
        endif
        h(i)=sqrt(h(i))
     enddo
     nfft0=nfft
  endif

  fac=2.0/nfft
  c(1:npts)=fac*d(1:npts)
  c(npts+1:nfft)=0.
  call four2a(c,nfft,1,-1,1)               !Forward c2c FFT

!  do i=1,nh
!     f=(i-1)*df
!     s(i)=real(c(i))**2 + aimag(c(i))**2
!     write(12,3001) f,s(i),db(s(i))
!3001 format(3f12.3)
!  enddo

!  ia=700.0/df
!  c(1:ia)=0.
!  ib=2300.0/df
!  c(ib:nfft)=0.

  c(1:nh+1)=h(1:nh+1)*c(1:nh+1)
  c(1)=0.5*c(1)                            !Half of DC term
  c(nh+2:nfft)=0.                          !Zero the negative frequencies
  call four2a(c,nfft,1,1,1)                !Inverse c2c FFT

  return
end subroutine analytic
