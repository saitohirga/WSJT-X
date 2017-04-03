program wsprlf

  parameter (NN=121)                    !Total symbols
!  parameter (NSPS=28672)                !Samples per symbol
  parameter (NSPS=28800)                !Samples per symbol
  parameter (NZ=NSPS*NN)                !Samples in waveform
  parameter (NFFT=11*NSPS)

  character*8 arg
  complex c(0:NZ-1)
  complex ct(0:NFFT-1)
  real*8 twopi,f0,dt,phi,dphi
  real s(0:NZ-1)
  real h0(0:NSPS/2)
  real h1(0:NSPS/2)
  real p(0:NFFT-1)
  real tmp(NN)
  integer id(NN)

  nargs=iargc()
  if(nargs.ne.2) then
     print*,'Usage: wsprlf f0 t1'
     goto 999
  endif
  call getarg(1,arg)
  read(arg,*) f0
  call getarg(2,arg)
  read(arg,*) t1

  call random_number(tmp)          !Generate random data
  id=0
  where(tmp.ge.0.5) id=1
  id(1)=0

  n1=nint(t1*NSPS)
  twopi=8.d0*atan(1.d0)

  do i=0,2*n1-1
     if(i.le.n1-1) then
        h0(i)=0.5*(1.0-cos(0.5*i*twopi/n1))
     else
        h1(i-n1)=0.5*(1.0-cos(0.5*i*twopi/n1))
     endif
  enddo
  if(t1.eq.0.0) h0=1
  if(t1.eq.0.0) h1=1

  s=1.
  s(0:n1-1)=h0(0:n1-1)           !Leading edge of 1st pulse
  do j=2,NN                      !Leading edges
     if(id(j).ne.id(j-1)) then
        ia=(j-1)*NSPS + 1
        ib=ia+n1-1
        s(ia:ib)=h0(0:n1-1)
     endif
  enddo
  do j=1,NN-1                    !Trailing edges
     if(id(j+1).ne.id(j)) then
        ib=j*NSPS
        ia=ib-n1+1
        s(ia:ib)=h1(0:n1-1)
     endif
  enddo
  ib=NN*NSPS-1
  ia=ib-n1+1
  s(ia:ib)=h1(0:n1-1)           !Trailing edge of last pulse

  dt=1.d0/12000.d0
  ts=dt*NSPS
  baud=12000.0/NSPS
  write(*,1000) baud,ts
1000 format('Baud:',f6.3,'  Tsym:',f6.3)
  phi=0.
  dphi=twopi*f0*dt
  i=-1
  do j=1,NN
     x=1.
     if(id(j).eq.1) x=-1.
     do k=1,NSPS
        i=i+1
        phi=phi+dphi
        if(phi.gt.twopi) phi=phi-twopi
        c(i)=x*s(i)*cmplx(cos(phi),sin(phi))
        t=i*dt
        sym=t/ts
        if(sym.ge.10.0 .and. sym.le.20.0) write(13,3001) t,   &
             sym,s(i),c(i)
3001    format(5f12.6,i10)
     enddo
  enddo

  p=0.
  do iblk=1,11
     ia=(iblk-1)*NFFT
     ib=ia+NFFT-1
     ct=c(ia:ib)
     call four2a(ct,NFFT,1,-1,1)
     do i=0,NFFT-1
        p(i)=p(i) + real(ct(i))**2 + aimag(ct(i))**2
     enddo
  enddo
     
  p=cshift(p,NFFT/2)/maxval(p)
  df=12000.0/NFFT
  do i=0,NFFT-1
     f=i*df - 6000.0
     write(14,1020) f,p(i),10.0*log10(p(i)+1.e-12)
1020 format(f12.4,2e12.3)
  enddo

999 end program wsprlf
