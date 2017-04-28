program wspr5sim

  include 'wsprlf_params.f90'
  character*12 arg
  character*22 msg,msgsent
  complex c0(0:NZ-1)
  complex c(0:NZ-1)
  integer itone(NZ)

! Get command-line argument(s)
  nargs=iargc()
  if(nargs.ne.5) then
     print*,'Usage:   wspr5sim "message" f0 DT nfiles snr'
     print*,'Example: wspr5sim "K1ABC FN42 30" 1500 0.0 10 -33'
     go to 999
  endif
  call getarg(1,msg)                             !Get message from command line
  call getarg(2,arg)
  read(arg,*) f0
  call getarg(3,arg)
  read(arg,*) xdt
  call getarg(4,arg)
  read(arg,*) nfiles
  call getarg(5,arg)
  read(arg,*) snrdb

  call genwspr5(msg,ichk,msgsent,itone,itype)

  txt=NN*NSPS0/12000.0
  write(*,1000) f0,xdt,txt,snrdb,nfiles,msgsent
1000 format('f0:',f9.3,'   DT:',f6.2,'   txt:',f6.1,'   SNR:',f6.1,    &
          '  nfiles:',i3,2x,a22)

  twopi=8.0*atan(1.0)
  fs=NSPS*12000.0/NSPS0                  !Sample rate
  dt=1.0/fs                              !Sample interval (s)
  tt=NSPS*dt                             !Duration of "itone" symbols (s)
  ts=2*NSPS*dt                           !Duration of OQPSK symbols (s)
  baud=1.0/tt                            !Keying rate for "itone" symbols (baud)
  txt=NZ*dt                              !Transmission length (s)
  bandwidth_ratio=2500.0/(fs/2.0)
  sig=sqrt(bandwidth_ratio) * 10.0**(0.05*snrdb)
  if(snrdb.gt.90.0) sig=1.0
  
  dphi0=twopi*(f0-0.25d0*baud)*dt
  dphi1=twopi*(f0+0.25d0*baud)*dt
  phi=0.d0
  c0=0.
  k=-1 + nint(xdt/dt)
  do j=1,NN
     dphi=dphi0
     if(itone(j).eq.1) dphi=dphi1
     if(k.eq.0) phi=-dphi
     do i=1,NSPS
        k=k+1
        phi=phi+dphi
        if(phi.gt.twopi) phi=phi-twopi
        xphi=phi
        if(k.ge.0 .and. k.lt.NZ) c0(k)=cmplx(cos(xphi),sin(xphi))
     enddo
  enddo
  c0=sig*c0                           !Scale to requested sig level

  do ifile=1,nfiles
     if(snrdb.lt.90) then
        do i=0,NZ-1                   !Add gaussian noise at specified SNR
           xnoise=gran()
           ynoise=gran()
           c(i)=c0(i) + cmplx(xnoise,ynoise)
        enddo
     endif
     write(10) c
  enddo
       
999 end program wspr5sim
