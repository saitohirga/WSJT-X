program jt9

! Decoder for JT9.  Can run stand-alone, reading data from *.wav files;
! or as the back end of wsjt-x, with data placed in a shared memory region.

  parameter (NTMAX=120)
  parameter (NMAX=NTMAX*12000)        !Total sample intervals per 30 minutes
  parameter (NDMAX=NTMAX*1500)        !Sample intervals at 1500 Hz rate
  parameter (NSMAX=1365)              !Max length of saved spectra
  integer*4 ihdr(11)
  real*4 s(NSMAX)
  real*4 ccfred(NSMAX)
  logical*1 lstrong(0:1023)
  integer*2 id2
  complex c0
  character*80 arg,infile
  common/jt9com/ss(184,NSMAX),savg(NSMAX),c0(NDMAX),id2(NMAX),nutc,ndiskdat,  &
       ntr,mousefqso,newdat,nfa,nfb,ntol,kin,nzhsym,nsynced,ndecoded
  common/tracer/limtrace,lu

  nargs=iargc()
  if(nargs.lt.1) then
     print*,'Usage: jt9 TRperiod ndepth file1 [file2 ...]'
     print*,'       Reads data from *.wav files.'
     print*,''
     print*,'       jt9 -s'
     print*,'       Gets data from shared memory region.'
     go to 999
  endif
  call getarg(1,arg)
  if(arg(1:2).eq.'-s') then
     call jt9a
     go to 999
  endif
  read(arg,*) ntrperiod
  call getarg(2,arg)
  read(arg,*) ndepth
  ifile1=3

  limtrace=0
  lu=12
  nfa=1000
  nfb=2000
  mousefqso=1500
  newdat=1
  ndiskdat=1

  do ifile=ifile1,nargs
     call getarg(ifile,infile)
     open(10,file=infile,access='stream',status='old',err=998)
     read(10) ihdr
     nutc0=ihdr(1)                           !Silence compiler warning
     i1=index(infile,'.wav')
     read(infile(i1-4:i1-1),*,err=1) nutc0
     go to 2
1    nutc0=0
2    nsps=0
     if(ntrperiod.eq.1)  then
        nsps=6912
        nzhsym=173
     else if(ntrperiod.eq.2)  then
        nsps=15360
        nzhsym=178
     else if(ntrperiod.eq.5)  then
        nsps=40960
        nzhsym=172
     else if(ntrperiod.eq.10) then
        nsps=82944
        nzhsym=171
     else if(ntrperiod.eq.30) then
        nsps=252000
        nzhsym=167
     endif
     if(nsps.eq.0) stop 'Error: bad TRperiod'

     kstep=nsps/2
     k=0
     nhsym0=-999
     npts=(60*ntrperiod-6)*12000
     if(ifile.eq.ifile1) then
        open(12,file='timer.out',status='unknown')
        call timer('jt9     ',0)
     endif

!     do i=1,npts
!        id2(i)=100.0*sin(6.283185307*1600.0*i/12000.0)
!     enddo

     id2=0                               !??? Why is this necessary ???

     do iblk=1,npts/kstep
        k=iblk*kstep
        call timer('read_wav',0)
        read(10,end=10) id2(k-kstep+1:k)
        call timer('read_wav',1)

        nhsym=(k-2048)/kstep
        if(nhsym.ge.1 .and. nhsym.ne.nhsym0) then
! Emit signal readyForFFT
           ingain=0
           call timer('symspec ',0)
           call symspec(k,ntrperiod,nsps,ingain,pxdb,s,ccfred,df3,  &
                ihsym,nzap,slimit,lstrong,npts8)
           call timer('symspec ',1)
           nhsym0=nhsym
           if(ihsym.ge.173) go to 10
        endif
     enddo

10   close(10)
     call fillcom(nutc0,ndepth)
     call decoder(ss,c0,1)
  enddo

  call timer('jt9     ',1)
  call timer('jt9     ',101)
  go to 999

998 print*,'Cannot open file:'
  print*,infile

999 end program jt9
