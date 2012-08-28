program mapsim

  parameter (NMAX=96000*60)
  integer*2 id2(2,NMAX)
  integer*2 id4(4,NMAX)
  real*4 d4(4,NMAX)
  complex cwave(NMAX)
  complex z,zx,zy
  real*8 fcenter,fsample,samfac,f,dt,twopi,phi,dphi
  character message*22,msgsent*22,arg*8

  nargs=iargc()
  if(nargs.ne.2) then
     print*,'Usage: mapsim "message" pol'
     go to 999
  endif
  call getarg(1,message)
  call getarg(2,arg)
  read(arg,*) pol

  open(10,file='000000_0000.iq',access='stream',status='unknown')
  open(11,file='000000_0000.tf2',access='stream',status='unknown')

  call noisegen(d4,NMAX)
  mode65=2
  samfac=1.d0
  call cgen65(message,mode65,samfac,nsendingsh,msgsent,cwave,nwave)

  fcenter=144.125d0
  fsample=96000.d0
  twopi=8.d0*atan(1.d0)
  rad=360.0/twopi
  a=cos(pol/rad)
  b=sin(pol/rad)
  dt=1.d0/fsample

  do isig=10,10
     f=-23 + 3*isig 
     dt=0.05d0*(isig-1)
!     snrdb=-(19.0 + (isig-1)/2.0)
     snrdb=-20.0
     sig=sqrt(2500.0/96000.0) * 10.0**(0.05*snrdb)
     sig=1.6*sig
     dphi=twopi*f*dt
     phi=0.
     i0=fsample*(3.5d0+dt)
     print*,f,dt,dphi,i0,sig

     do i=1,nwave
        phi=phi + dphi
!        if(phi.gt.twopi) phi=phi-twopi
!        xphi=phi
        z=sig*cwave(i)*cmplx(cos(phi),sin(phi))
        zx=a*z
        zy=b*z
        j=i+i0
        d4(1,j)=d4(1,j) + real(zx)
        d4(2,j)=d4(2,j) + aimag(zx)
        d4(3,j)=d4(3,j) + real(zy)
        d4(4,j)=d4(4,j) + aimag(zy)
     enddo
  enddo

  s=31.6
  do i=1,NMAX
     id4(1,i)=nint(s*d4(1,i))
     id4(2,i)=nint(s*d4(2,i))
     id4(3,i)=nint(s*d4(3,i))
     id4(4,i)=nint(s*d4(4,i))
     id2(1,i)=id4(1,i)
     id2(2,i)=id4(2,i)
  enddo

  write(10) fcenter,id2
  write(11) fcenter,id4

999 end program mapsim
