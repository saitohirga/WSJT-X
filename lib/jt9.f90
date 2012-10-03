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
  logical*1 lstrong(0:1023)
  integer*1 i1SoftSymbols(207)
  character*22 msg
  integer*2 id2
  complex c0
  common/jt8com/id2(NMAX),ss(184,NSMAX),savg(NSMAX),c0(NDMAX),    &
       nutc,npts8,junk(20)
  common/tracer/limtrace,lu

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
  if(arg(1:2).eq.'-s') then
!     call jt9a
!     call ftnquit
     go to 999
  endif
  read(arg,*) ntrperiod

  ifile1=2
  limtrace=0
  lu=12
  call timer('jt9     ',0)                      !###

  nfa=1000
  nfb=2000
  ntol=500
  mousedf=0
  mousefqso=1500
  newdat=1
  nb=0
  nbslider=100

!  call ftninit('.')

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
     call timer('read_wav',0)
     read(10) id2(1:npts)
     call timer('read_wav',1)

!     do i=1,npts
!        id2(i)=100.0*sin(6.283185307*1046.875*i/12000.0)
!     enddo

!     if(ifile.eq.ifile1) call timer('jt9     ',0)
     do iblk=1,npts/kstep
        k=iblk*kstep
        nhsym=(k-2048)/kstep
        if(nhsym.ge.1 .and. nhsym.ne.nhsym0) then
! Emit signal readyForFFT
           call timer('symspec ',0)
           call symspecx(k,ntrperiod,nsps,ndiskdat,nb,nbslider,pxdb,   &
                s,f0a,df3,ihsym,nzap,slimit,lstrong)
           call timer('symspec ',1)
           nhsym0=nhsym
           if(ihsym.ge.184) go to 10
        endif
     enddo

10   continue

     do i=0,512
        if(lstrong(i)) print*,'Strong signal at ',12000.0*i/1024.0
     enddo

     nz=1000.0/df3
     do i=1,nz
        freq=f0a + (i-1)*df3
        write(78,3001) i,freq,savg(i)
3001    format(i8,2f12.3)
     enddo

     nutc=nutc0
     nstandalone=1
     call sync9(ss,tstep,f0a,df3,lagpk,fpk)
     call spec9(c0,npts8,nsps,f0a,lagpk,fpk,i1SoftSymbols)
     call decode9(i1SoftSymbols,msg)
     print*,msg
  enddo

  call timer('jt9     ',1)
  call timer('jt9     ',101)
!  call ftnquit
  go to 999

998 print*,'Cannot open file:'
  print*,infile

999 end program jt9
