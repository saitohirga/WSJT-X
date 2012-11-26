program jt9test

! Decoder for JT9.  Can run stand-alone, reading data from *.wav files;
! or as the back end of wsjt-x, with data placed in a shared memory region.

! NB: For unknown reason, ***MUST*** be compiled by g95 with -O0 !!!

  character*80 arg,infile
  parameter (NMAX=1800*12000)        !Total sample intervals per 30 minutes
  parameter (NDMAX=1800*1500)        !Sample intervals at 1500 Hz rate
  parameter (NSMAX=22000)            !Max length of saved spectra
  integer*4 ihdr(11)
  real*4 s(NSMAX)
  real*4 ccfred(NSMAX)
  logical*1 lstrong(0:1023)
  integer*1 i1SoftSymbols(207)
  character*22 msg
  character*33 line
  integer*2 id2
  complex c0
  complex c1(0:2700000)
  common/jt9com/ss(184,NSMAX),savg(NSMAX),c0(NDMAX),id2(NMAX),nutc,ndiskdat,  &
       ntr,mousefqso,newdat,nfa,nfb,ntol,kin,nzhsym,nsynced,ndecoded
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
!    call ftnquit
     go to 999
  endif
  read(arg,*) ntrperiod

  ifile1=2

  limtrace=0
  lu=12
  nfa=1000
  nfb=2000
  ntol=500
  nfqso=1500
  newdat=1
  nb=0
  nbslider=100
  limit=20000
  ndiskdat=1

  do ifile=ifile1,nargs
     call getarg(ifile,infile)
     open(10,file=infile,access='stream',status='old',err=998)
     read(10) ihdr
     i1=index(infile,'.wav')
     read(infile(i1-4:i1-1),*,err=1) nutc0
     go to 2
1    nutc0=0
2    nsps=0
     if(ntrperiod.eq.1)  then
        nsps=6912
        nzhsym=181
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
     tstep=kstep/12000.0
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
           call symspec(k,ntrperiod,nsps,ingain,nb,nbslider,pxdb,   &
                s,ccfred,df3,ihsym,nzap,slimit,lstrong,npts8)
           call timer('symspec ',1)
           nhsym0=nhsym
           if(ihsym.ge.184) go to 10
        endif
     enddo
10   close(10)

     nsps8=nsps/8
     iz=1000.0/df3
     nutc=nutc0

     call timer('sync9   ',0)
     call sync9(ss,nzhsym,tstep,df3,ntol,nfqso,ccfred,ia,ib,ipk) !Get sync, freq
     call timer('sync9   ',1)

     fgood=0.
     df8=1500.0/(nsps/8)
     sbest=0.
     do i=ia,ib
        f=(i-1)*df3
        if((i.eq.ipk .or. ccfred(i).ge.3.0) .and. f.gt.fgood+10.0*df8) then

           call timer('test9   ',0)
           fpk=1000.0 + df3*(i-1)
           c1(0:npts8-1)=conjg(c0(1:npts8))
           call test9(c1,npts8,nsps8,fpk,syncpk,snrdb,xdt,freq,drift,   &
                i1SoftSymbols)
           call timer('test9   ',1)

           call timer('decode9 ',0)
           call decode9(i1SoftSymbols,limit,nlim,msg)
           call timer('decode9 ',1)
           snr=snrdb
           sync=syncpk - 2.0
           if(sync.lt.0.0) sync=0.0
           nsync=sync
           if(nsync.gt.10) nsync=10
           nsnr=nint(snr)
           width=0.0

           if(sync.gt.sbest .and. fgood.eq.0.0) then
              sbest=sync
              write(line,1010) nutc,nsync,nsnr,xdt,1000.0+fpk,width
              if(nsync.gt.0) nsynced=1
           endif

           if(msg.ne.'                      ') then
              write(*,1010) nutc,nsync,nsnr,xdt,freq,drift,msg
1010          format(i4.4,i4,i5,f6.1,f8.2,f6.2,3x,a22)
              fgood=f
              nsynced=1
              ndecoded=1
           endif
        endif
     enddo

     if(fgood.eq.0.0) then
        write(*,1020) line
1020    format(a33)
     endif

  enddo

  call timer('jt9     ',1)
  call timer('jt9     ',101)
!  call ftnquit
  go to 999

998 print*,'Cannot open file:'
  print*,infile

999 end program jt9test
