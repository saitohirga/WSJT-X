program mapsim

  parameter (NMAX=96000*60)
  integer*2 id2(2,NMAX)
  integer*2 id4(4,NMAX)
  real*4 d4(4,NMAX)
  complex cwave(NMAX)
  complex z,zx,zy
  real*8 fcenter,fsample,samfac,f,dt,twopi,phi,dphi
  character message*22,msgsent*22,arg*8,fname*14,mode*2

  nargs=iargc()
  if(nargs.ne.9) then
     print*,'Usage: mapsim level "message"    mode f1 f2 nsigs pol SNR nfiles'
     print*,'Example:        25 "CQ K1ABC FN42" B -22 33  20    45 -20    1'
     go to 999
  endif
  call getarg(1,arg)
  read(arg,*) rmsdb
  rms=10.0**(0.05*rmsdb)
  call getarg(2,message)
  call getarg(3,mode)
  call getarg(4,arg)
  read(arg,*) f1
  call getarg(5,arg)
  read(arg,*) f2
  call getarg(6,arg)
  read(arg,*) nsigs
  call getarg(7,arg)
  read(arg,*) npol
  call getarg(8,arg)
  read(arg,*) snrdb
  pol=npol
  call getarg(9,arg)
  read(arg,*) nfiles

  fcenter=144.125d0
  fsample=96000.d0
  dt=1.d0/fsample
  twopi=8.d0*atan(1.d0)
  rad=360.0/twopi
  samfac=1.d0
  mode65=1
  if(mode(1:1).eq.'B') mode65=2
  if(mode(1:1).eq.'C') mode65=4

  write(*,1000)
1000 format('  N   freq     S/N  pol  Message'/    &
            '-----------------------------------------------')

  do ifile=1,nfiles
     nmin=ifile-1
     if(mode(2:2).eq.' ') nmin=2*nmin
     write(fname,1002) nmin
1002 format('000000_',i4.4,'00')
     open(10,file=fname//'.iq',access='stream',status='unknown')
     open(11,file=fname//'.tf2',access='stream',status='unknown')

     call noisegen(d4,NMAX)
     call cgen65(message,mode65,samfac,nsendingsh,msgsent,cwave,nwave)

     do isig=1,nsigs
        if(npol.lt.0) pol=(isig-1)*180.0/nsigs
        a=cos(pol/rad)
        b=sin(pol/rad)
!        f=-23000 + 3000*(isig-1)
        f=1000.0*(f1 + (isig-1)*(f2-f1)/(nsigs-1.0))
        dphi=twopi*f*dt + 0.5*twopi

        snrdbx=snrdb
        if(snrdb.ge.-1.0) snrdbx=-15.0 - 15.0*(isig-1.0)/nsigs
        sig=sqrt(2.2*2500.0/96000.0) * 10.0**(0.05*snrdbx)
        write(*,1020) isig,0.001*f,snrdbx,nint(pol),message
1020    format(i3,f8.3,f7.1,i5,2x,a22)

        phi=0.
        i0=fsample*(3.5d0+0.05d0*(isig-1))

        do i=1,nwave
           phi=phi + dphi
           if(phi.lt.-twopi) phi=phi+twopi
           if(phi.gt.twopi) phi=phi-twopi
           xphi=phi
           z=sig*cwave(i)*cmplx(cos(xphi),-sin(xphi))
           zx=a*z
           zy=b*z
           j=i+i0
           d4(1,j)=d4(1,j) + real(zx)
           d4(2,j)=d4(2,j) + aimag(zx)
           d4(3,j)=d4(3,j) + real(zy)
           d4(4,j)=d4(4,j) + aimag(zy)
        enddo
     enddo

     do i=1,NMAX
        id4(1,i)=nint(rms*d4(1,i))
        id4(2,i)=nint(rms*d4(2,i))
        id4(3,i)=nint(rms*d4(3,i))
        id4(4,i)=nint(rms*d4(4,i))
        id2(1,i)=id4(1,i)
        id2(2,i)=id4(2,i)
     enddo

     write(10) fcenter,id2
     write(11) fcenter,id4
     close(10)
     close(11)
  enddo

999 end program mapsim
