program wsprlf

  parameter (NN=121)                    !Total symbols
  parameter (NSPS=28800)                  !Samples per symbol @ fs=12000 Hz
  parameter (NZ=NSPS*NN)                !Samples in waveform
  
  character*8 arg
  complex c(0:NZ-1)
  real*8 twopi,fs,f0,dt,phi,dphi
  real x(0:NZ-1)
  real p(0:NZ/2)
  real h0(0:NSPS/2)                     !Pulse shape, rising edge
  real h1(0:NSPS/2)                     !Pulse shape, trailing edge
  real tmp(NN)
  integer id(NN)                        !Generated data
  integer ie(NN)                        !Differentially encoded data
  data fs/12000.d0/

  nargs=iargc()
  if(nargs.ne.3) then
     print*,'Usage: wsprlf f0 t1 snr'
     goto 999
  endif
  call getarg(1,arg)
  read(arg,*) f0
  call getarg(2,arg)
  read(arg,*) t1
  call getarg(3,arg)
  read(arg,*) snrdb

  call random_number(tmp)          !Generate random bipolar data
  id=1
  where(tmp.lt.0.5) id=-1
  ie(1)=1
  do i=2,NN                        !Differentially encode
     ie(i)=id(i)*ie(i-1)
  enddo

  n1=nint(t1*NSPS)
  twopi=8.d0*atan(1.d0)

  do i=0,2*n1-1                    !Define the shape functions
     if(i.le.n1-1) then
        h0(i)=0.5*(1.0-cos(0.5*i*twopi/n1))
     else
        h1(i-n1)=0.5*(1.0-cos(0.5*i*twopi/n1))
     endif
  enddo
  if(t1.eq.0.0) h0=1
  if(t1.eq.0.0) h1=1

! Shape the channel pulses
  x=1.
  x(0:n1-1)=h0(0:n1-1)           !Leading edge of 1st pulse
  do j=2,NN                      !Leading edges
     if(ie(j).ne.ie(j-1)) then
        ia=(j-1)*NSPS + 1
        ib=ia+n1-1
        x(ia:ib)=h0(0:n1-1)
     endif
  enddo
  do j=1,NN-1                    !Trailing edges
     if(ie(j+1).ne.ie(j)) then
        ib=j*NSPS
        ia=ib-n1+1
        x(ia:ib)=h1(0:n1-1)
     endif
  enddo
  ib=NN*NSPS-1
  ia=ib-n1+1
  x(ia:ib)=h1(0:n1-1)           !Trailing edge of last pulse

  dt=1.d0/fs
  ts=dt*NSPS
  baud=fs/NSPS
  write(*,1000) baud,ts
1000 format('Baud:',f6.3,'  Tsym:',f6.3)

  dphi=twopi*f0*dt
  phi=0.d0
  i=-1
  do j=1,NN                     !Generate the baseband waveform
     a=ie(j)
     do k=1,NSPS
        i=i+1
        x(i)=a*x(i)
        phi=phi+dphi
        if(phi.gt.twopi) phi=phi-twopi
        xphi=phi
        c(i)=x(i)*cmplx(cos(xphi),sin(xphi))
        sym=i*dt/ts
        if(j.le.20) write(13,1010) sym,x(i),c(i)
1010    format(4f12.6)
     enddo
  enddo

  call four2a(c,NZ,1,-1,1)      !To freq domain
  df=fs/NZ
  nh=NZ/2
  do i=0,nh
     f=i*df
     p(i)=real(c(i))**2 + aimag(c(i))**2
  enddo
  p=p/maxval(p)
  do i=0,nh                      !Save spectrum for plotting
     write(14,1020) i*df,p(i),10.0*log10(p(i)+1.e-8)
1020 format(f10.3,2e12.3)
  enddo

999 end program wsprlf
