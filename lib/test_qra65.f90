program test_qra65

  character*71 cmd1,cmd2,line
  character*22 msg
  character*8 arg
  character*1 csubmode
  integer nretcode(0:11)
  logical decok

  nargs=iargc()
  if(nargs.ne.9) then
     print*,'Usage:   test_qra65        "msg"       A-D depth freq  DT fDop TRp nfiles SNR'
     print*,'Example: test_qra65 "K1ABC W9XYZ EN37"  A    3   1500 0.0  5.0  60  100   -20'
     print*,'         SNR = 0 to loop over all relevant SNRs'
     go to 999
  endif
  call getarg(1,msg)
  call getarg(2,csubmode)
  call getarg(3,arg)
  read(arg,*) ndepth
  call getarg(4,arg)
  read(arg,*) nf0
  call getarg(5,arg)
  read(arg,*) dt
  call getarg(6,arg)
  read(arg,*) fDop
  call getarg(7,arg)
  read(arg,*) ntrperiod
  call getarg(8,arg)
  read(arg,*) nfiles
  call getarg(9,arg)
  read(arg,*) nsnr

  if(ntrperiod.eq.15) then
     nsps=1800
     i50=-21
  else if(ntrperiod.eq.30) then
     nsps=3600
     i50=-24
  else if(ntrperiod.eq.60) then
     nsps=7680
     i50=-28
  else if(ntrperiod.eq.120) then
     nsps=16000
     i50=-31
  else if(ntrperiod.eq.300) then
     nsps=41472
     i50=-35
  else
     stop 'Invalid TR period'
  endif
  ia=i50 + 8
  ib=i50 - 5
  if(nsnr.ne.0) then
     ia=nsnr
     ib=nsnr
  endif

  baud=12000.0/nsps
  tsym=1.0/baud

!                1         2         3         4         5         6         7
!       12345678901234567890123456789012345678901234567890123456789012345678901'
  cmd1='qra65sim "K1ABC W9XYZ EN37      " A 1500  5.0  0.0  60  100 -10 > junk0'
  cmd2='jt9 -3 -p  15 -L 300 -H 3000 -d 3 -b A *.wav > junk'

  write(cmd1(10:33),'(a)') '"'//msg//'"'
  cmd1(35:35)=csubmode
  write(cmd1(37:40),'(i4)') nf0
  write(cmd1(41:45),'(f5.1)') fDop
  write(cmd1(46:50),'(f5.2)') dt
  write(cmd1(51:54),'(i4)') ntrperiod
  write(cmd1(55:59),'(i5)') nfiles
  write(cmd2(11:13),'(i3)') ntrperiod
  write(cmd2(33:33),'(i1)') ndepth
  cmd2(38:38)=csubmode
  call system('rm -f *.wav')

  write(*,1000) (j,j=0,11)
  write(12,1000) (j,j=0,11)
1000 format(/'SNR d  Dop Sync Dec1 DecN Bad',i6,11i4,'  tdec dtavg dtrms'/97('-'))

  dterr=tsym/4.0
  nferr=max(1,nint(0.5*baud),nint(fdop/3.0))
  ndecodes0=nfiles
  
  do nsnr=ia,ib,-1
     nsync=0
     ndecodes=0
     nfalse=0
     nretcode=0
     navg=0
     write(cmd1(61:63),'(i3)') nsnr
     call system(cmd1)
     call sec0(0,tdec)
     call system(cmd2)
     call sec0(1,tdec)
     open(10,file='junk',status='unknown')
     n=0
     do iline=1,9999
        read(10,'(a71)',end=10) line
        if(index(line,'<Decode').eq.1) cycle
        read(line(11:20),*) xdt,nf
        if(ntrperiod.ge.60) xdt=xdt-0.5              !### TEMPORARY ###
        decok=index(line,'W9XYZ').gt.0
        if((abs(xdt-dt).le.dterr .and. abs(nf-nf0).le.nferr) .or. decok) then
           nsync=nsync+1
        endif
        irc=-1
        if(line(23:23).ne.' ') read(line(60:),*) irc,iavg
        if(irc.lt.0) cycle
        if(decok) then
           i=irc
           if(i.le.11) then
              ndecodes=ndecodes + 1
              navg=navg + 1
           else
              i=mod(i,10)
              navg=navg + 1
           endif
           nretcode(i)=nretcode(i) + 1
        else
           nfalse=nfalse + 1
           print*,'False: ',line
        endif
     enddo
10   close(10)
     xdt_avg=0.
     xdt_rms=0.
     write(*,1100) nsnr,ndepth,fDop,nsync,ndecodes,navg,nfalse,nretcode,   &
          tdec/nfiles
     write(12,1100) nsnr,ndepth,fDop,nsync,ndecodes,navg,nfalse,nretcode,  &
          tdec/nfiles
1100 format(i3,i2,f5.1,3i5,i4,i6,11i4,f6.2)
     if(ndecodes.lt.nfiles/2 .and. ndecodes0.ge.nfiles/2) then
        snr_thresh=nsnr + float(nfiles/2 - ndecodes)/(ndecodes0-ndecodes)
        write(13,1200) ndepth,fdop,csubmode,snr_thresh
1200    format(i1,f6.1,2x,a1,f7.1)
        flush(13)
     endif
     flush(6)
     flush(12)
     ndecodes0=ndecodes
  enddo  ! nsnr

999 end program test_qra65

  include 'sec0.f90'

