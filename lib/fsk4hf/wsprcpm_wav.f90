subroutine wsprcpm_wav(baud,xdt,h1,h2,f0,itone,snrdb,iwave)

! Generate iwave() from itone().
  
  include 'wsprcpm_params.f90'
  parameter (NMAX=120*12000)
  integer itone(NN)
  integer*2 iwave(NMAX)
  real*8 twopi,dt,dphi0,dphi1,dphi,phi
  real dat(NMAX)

  twopi=8.d0*atan(1.d0)
  dt=1.d0/12000.d0

  dat=0.
  if(snrdb.lt.90) then
     do i=1,NMAX
        dat(i)=gran()          !Generate gaussian noise
     enddo
     bandwidth_ratio=2500.0/6000.0
     sig=sqrt(2*bandwidth_ratio)*10.0**(0.05*snrdb)
  else
     sig=1.0
  endif

  dphi01=twopi*(f0-(h1/2.0d0)*baud)*dt
  dphi11=twopi*(f0+(h1/2.0d0)*baud)*dt
  dphi02=twopi*(f0-(h2/2.0d0)*baud)*dt
  dphi12=twopi*(f0+(h2/2.0d0)*baud)*dt
  phi=0.d0
  k=nint(xdt/dt)
  do j=1,NN
     if( mod(j,2).eq.0 ) then
       dphi0=dphi01
       dphi1=dphi11
     else
       dphi0=dphi02
       dphi1=dphi12
     endif
     dphi=dphi0
     if(itone(j).eq.1) dphi=dphi1
     if(k.eq.0) phi=-dphi
     do i=1,NSPS0
        k=k+1
        phi=phi+dphi
        if(phi.gt.twopi) phi=phi-twopi
        xphi=phi
        if(k.gt.0 .and. k.le.NMAX) dat(k)=dat(k) + sig*sin(xphi)
     enddo
  enddo
  fac=32767.0
  rms=100.0
  if(snrdb.ge.90.0) iwave=nint(fac*dat)
  if(snrdb.lt.90.0) iwave=nint(rms*dat)

  return
end subroutine wsprcpm_wav
