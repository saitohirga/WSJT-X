! Fortran logical units used in WSJT6
!
!   10  binary input data, *.tf2 files
!   11  decoded.txt
!   12  decoded.ave
!   13  tsky.dat
!   14  azel.dat
!   15  
!   16
!   17  saved *.tf2 files
!   18  test file to be transmitted (wsjtgen.f90)
!   19  messages.txt
!   20  bandmap.txt
!   21  ALL65.TXT
!   22  kvasd.dat
!   23  CALL3.TXT
!   24  meas24.dat
!   25  meas25.dat
!   26  tmp26.txt
!   27  dphi.txt
!   28  
!   29  debug.txt
!------------------------------------------------ ftn_init
subroutine ftn_init

  character*1 cjunk
  integer ptt
  include 'gcom1.f90'
  include 'gcom2.f90'
  include 'gcom3.f90'
  include 'gcom4.f90'

!  print*,'ftn_init.F90 nport=', nport, 'pttport=', pttport
  i=ptt(nport,pttport,0,iptt)                       !Clear the PTT line
  addpfx='    '
  nrw26=0

  do i=80,1,-1
     if(AppDir(i:i).ne.' ') goto 1
  enddo
1 iz=i
  lenappdir=iz
  call pfxdump(appdir(:iz)//'/prefixes.txt')

  do i=80,1,-1
     if(AzElDir(i:i).ne.' ') goto 2
  enddo
2 iz2=i

#ifdef CVF
  open(11,file=appdir(:iz)//'/decoded.txt',status='unknown',               &
       share='denynone',err=910)
#else
  open(11,file=appdir(:iz)//'/decoded.txt',status='unknown',               &
       err=910)
#endif
  endfile 11

#ifdef CVF
  open(12,file=appdir(:iz)//'/decoded.ave',status='unknown',               &
       share='denynone',err=920)
#else
  open(12,file=appdir(:iz)//'/decoded.ave',status='unknown',               &
       err=920)
#endif
  endfile 12

#ifdef CVF
  open(14,file=azeldir(:iz2)//'/azel.dat',status='unknown',                  &
       share='denynone',err=930)
#else
  open(14,file=azeldir(:iz2)//'/azel.dat',status='unknown',                  &
       err=930)
#endif

#ifdef CVF
  open(19,file=appdir(:iz)//'/messages.txt',status='unknown',               &
       share='denynone',err=911)
#else
  open(19,file=appdir(:iz)//'/messages.txt',status='unknown',               &
       err=911)
#endif
  endfile 19

#ifdef CVF
  open(20,file=appdir(:iz)//'/bandmap.txt',status='unknown',               &
       share='denynone',err=912)
#else
  open(20,file=appdir(:iz)//'/bandmap.txt',status='unknown',               &
       err=912)
#endif
  endfile 20

#ifdef CVF
  open(21,file=appdir(:iz)//'/ALL65.TXT',status='unknown',                   &
       access='append',share='denynone',err=950)
#else
  open(21,file=appdir(:iz)//'/ALL65.TXT',status='unknown',                   &
	access='append',err=950)
  do i=1,9999999
     read(21,*,end=10) cjunk
  enddo
10 continue
#endif

#ifdef CVF
  open(22,file=appdir(:iz)//'/kvasd.dat',access='direct',recl=1024,        &
       status='unknown',share='denynone')
#else
  open(22,file=appdir(:iz)//'/kvasd.dat',access='direct',recl=1024,        &
       status='unknown')
#endif

#ifdef CVF
  open(24,file=appdir(:iz)//'/meas24.txt',status='unknown',                 &
       share='denynone')
#else
  open(24,file=appdir(:iz)//'/meas24.txt',status='unknown')
#endif

#ifdef CVF
  open(25,file=appdir(:iz)//'/meas25.txt',status='unknown',                 &
       share='denynone')
#else
  open(25,file=appdir(:iz)//'/meas25.txt',status='unknown')
#endif

#ifdef CVF
  open(26,file=appdir(:iz)//'/tmp26.txt',status='unknown',                 &
       share='denynone')
#else
  open(26,file=appdir(:iz)//'/tmp26.txt',status='unknown')
#endif

#ifdef CVF
  open(27,file=appdir(:iz)//'/dphi.txt',status='unknown',                 &
       share='denynone')
#else
  open(27,file=appdir(:iz)//'/dphi.txt',status='unknown')
#endif

#ifdef CVF
  open(29,file=appdir(:iz)//'/debug.txt',status='unknown',                 &
       share='denynone')
#else
  open(29,file=appdir(:iz)//'/debug.txt',status='unknown')
#endif


  return

910 print*,'Error opening DECODED.TXT'
  stop
911 print*,'Error opening messages.txt'
  stop
912 print*,'Error opening bandmap.txt'
  stop
920 print*,'Error opening DECODED.AVE'
  stop
930 print*,'Error opening AZEL.DAT'
  stop
950 print*,'Error opening ALL65.TXT'
  stop

end subroutine ftn_init
