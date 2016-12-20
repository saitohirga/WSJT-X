subroutine analytic(d,npts,nfft,c,a,equalize)

! Convert real data to analytic signal

  parameter (NFFTMAX=1024*1024)
  real d(npts)
  complex h(NFFTMAX/2)
  real*8 a(5),alast(5),fp
  real ac(5),a0(5)
  complex c(NFFTMAX)
  logical*1 equalize
  data nfft0/0/
  data alast/0.0,0.0,0.0,0.0,0.0/
  data ac/1.0,0.05532,0.11438,0.12918,0.09274/ ! amp coeffs for TS2000
  data a0/0.0,0.0,-0.952,0.768,-0.565/  ! baseline phase coeffs for TS2000
  save nfft0,h,alast,a0,ac

! disable baseline phase correction for commit - should look for a file with coeffs
  a0(1:5)=0.0

  df=12000.0/nfft
  nh=nfft/2
  if( nfft.ne.nfft0 .or. any(alast .ne. a) ) then
     t=1.0/2000.0
     beta=0.1
     pi=4.0*atan(1.0)
     do i=1,nh+1
        ff=(i-1)*df
        f=ff-1500.0
        fp=f/1000.0
        h(i)=cmplx(1.0,0.0)
        if( equalize ) then
          phase0=a0(1)+fp*(a0(2)+fp*(a0(3)+fp*(a0(4)+fp*a0(5))))
          phase=a(1)+fp*(a(2)+fp*(a(3)+fp*(a(4)+fp*a(5))))
!          amp=ac(1)+fp*(ac(2)+fp*(ac(3)+fp*(ac(4)+fp*ac(5))))
          amp=1.0   ! no amplitude correction for now
          h(i)=amp*cmplx(cos(phase),sin(phase))*cmplx(cos(phase0),sin(phase0))
        endif
        if(abs(f).gt.(1-beta)/(2*t) .and. abs(f).le.(1+beta)/(2*t)) then
           h(i)=h(i)*0.5*(1+cos((pi*t/beta )*(abs(f)-(1-beta)/(2*t))))
        endif
     enddo
     nfft0=nfft
  endif

  fac=2.0/nfft
  c(1:npts)=fac*d(1:npts)
  c(npts+1:nfft)=0.
  call four2a(c,nfft,1,-1,1)               !Forward c2c FFT

  c(1:nh+1)=h(1:nh+1)*c(1:nh+1)
  c(1)=0.5*c(1)                            !Half of DC term
  c(nh+2:nfft)=0.                          !Zero the negative frequencies
  call four2a(c,nfft,1,1,1)                !Inverse c2c FFT
  alast=a
  return
end subroutine analytic
