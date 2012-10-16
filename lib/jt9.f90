program jt9

! Decoder for JT9.  Can run stand-alone, reading data from *.wav files;
! or as the back end of wsjt-x, with data placed in a shared memory region.

! NB: For unknown reason, ***MUST*** be compiled by g95 with -O0 !!!

  character*80 arg,infile
  parameter (NMAX=1800*12000)        !Total sample intervals per 30 minutes
  parameter (NDMAX=1800*1500)        !Sample intervals at 1500 Hz rate
  parameter (NSMAX=22000)            !Max length of saved spectra
  integer*4 ihdr(11)
  real*4 s(NSMAX)
  real*4 red(NSMAX)
  logical*1 lstrong(0:1023)
  integer*1 i1SoftSymbols(207)
  character*22 msg
  integer*2 id2
  complex c0(NDMAX)
  common/jt9com/ss(184,NSMAX),savg(NSMAX),id2(NMAX),nutc,ndiskdat,    &
       ntr,mousefqso,nagain,newdat,nfa,nfb,ntol,kin

  nargs=iargc()
  if(nargs.lt.1) then
     print*,'Usage: jt9 TRperiod file1 [file2 ...]'
     print*,'       Reads data from *.wav files.'
     print*,''
     print*,'       jt9 -s'
     print*,'       Gets data from shared memory region.'
     go to 999
  endif
  call getarg(1,arg)
  if(arg(1:2).eq.'-s') go to 999
  read(arg,*) ntrperiod

  ifile1=2

  nfa=1000
  nfb=2000
  ntol=500
  nfqso=1500
  newdat=1
  nb=0
  nbslider=100

  do ifile=ifile1,nargs
     call getarg(ifile,infile)
     open(10,file=infile,access='stream',status='old',err=998)
     read(10) ihdr
     i1=index(infile,'.wav')
     read(infile(i1-4:i1-1),*,err=1) nutc0
     go to 2
1    nutc0=0
2    nsps=0
     if(ntrperiod.eq.1)  nsps=6912
     if(ntrperiod.eq.2)  nsps=15360
     if(ntrperiod.eq.5)  nsps=40960
     if(ntrperiod.eq.10) nsps=82944
     if(ntrperiod.eq.30) nsps=252000
     if(nsps.eq.0) stop 'Error: bad TRprtiod'

     kstep=nsps/2
     tstep=kstep/12000.0
     k=0
     nhsym0=-999
     npts=(60*ntrperiod-6)*12000

!     do i=1,npts
!        id2(i)=100.0*sin(6.283185307*1046.875*i/12000.0)
!     enddo

     do iblk=1,npts/kstep
        k=iblk*kstep
        read(10,end=10) id2(k-kstep+1:k)
        nhsym=(k-2048)/kstep
        if(nhsym.ge.1 .and. nhsym.ne.nhsym0) then
! Emit signal readyForFFT
           call symspec(k,ntrperiod,nsps,nb,nbslider,pxdb,   &
                s,red,df3,ihsym,nzap,slimit,lstrong,c0,npts8)
           nhsym0=nhsym
           if(ihsym.ge.184) go to 10
        endif
     enddo

10   close(10)
     iz=1000.0/df3
!     print*,'A',ihsym,nhsym,tstep,df3,ntol,nfqso

! Now do the decoding
     nutc=nutc0

! Get sync, approx freq
     call sync9(ss,tstep,df3,ntol,nfqso,sync,fpk,red)
!     print*,'B',sync,fpk,npts8,nsps
     call spec9(c0,npts8,nsps,fpk,xdt,i1SoftSymbols)
     call decode9(i1SoftSymbols,msg)
     write(*,1010) nutc,sync,xdt,1000.0+fpk,msg
1010 format(i4.4,3f7.1,2x,a22)
  enddo

  go to 999

998 print*,'Cannot open file:'
  print*,infile

999 end program jt9
