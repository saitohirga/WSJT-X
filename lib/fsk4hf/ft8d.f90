program ft8d

! Decode FT8 data read from *.wav files.

  include 'ft8_params.f90'
  character*12 arg
  character infile*80,datetime*13,message*22
  real s(NH1,NHSYM)
  real candidate(3,100)
  integer ihdr(11)
  integer*2 iwave(NMAX)                 !Generated full-length waveform  
  real dd(NMAX)
 
  nargs=iargc()
  if(nargs.lt.3) then
     print*,'Usage:   ft8d MaxIt Norder file1 [file2 ...]'
     print*,'Example  ft8d   40     2   *.wav'
     go to 999
  endif
  call getarg(1,arg)
  read(arg,*) max_iterations
  call getarg(2,arg)
  read(arg,*) norder
  nfiles=nargs-2

  twopi=8.0*atan(1.0)
  fs=12000.0                             !Sample rate
  dt=1.0/fs                              !Sample interval (s)
  tt=NSPS*dt                             !Duration of "itone" symbols (s)
  ts=2*NSPS*dt                           !Duration of OQPSK symbols (s)
  baud=1.0/tt                            !Keying rate (baud)
  txt=NZ*dt                              !Transmission length (s)
  nfa=100.0
  nfb=3000.0
  nfqso=1500.0

  do ifile=1,nfiles
     call getarg(ifile+2,infile)
     open(10,file=infile,status='old',access='stream')
     read(10,end=999) ihdr,iwave
     close(10)
     j2=index(infile,'.wav')
     read(infile(j2-6:j2-1),*) nutc
     datetime=infile(j2-13:j2-1)
     call sync8(iwave,nfa,nfb,nfqso,s,candidate,ncand)
     syncmin=2.0
     dd=iwave
     do icand=1,ncand
       sync=candidate(3,icand)
       if( sync.lt.syncmin) cycle
       f1=candidate(1,icand)
       xdt=candidate(2,icand)
       nsnr=min(99,nint(10.0*log10(sync)-25.5))
       call ft8b(dd,nfqso,f1,xdt,nharderrors,dmin,nbadcrc,message,xsnr)
       nsnr=xsnr
       xdt=xdt-0.6
       write(*,1110) datetime,0,nsnr,xdt,f1,message,nharderrors,dmin
1110   format(a13,2i4,f6.2,f7.1,' ~ ',a22,i6,f7.1)
     enddo
  enddo   ! ifile loop

999 end program ft8d
  
