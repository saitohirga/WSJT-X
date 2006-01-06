! Fortran logical units used in WSJT6
!
!   10  wave files read from disk
!   11  decoded.txt
!   12  decoded.ave
!   13  tsky.dat
!   14  azel.dat
!   15  debug.txt
!   16  c:/wsjt.reg 
!   17  wave files written to disk
!   18  test file to be transmitted (wsjtgen.f90)
!   19
!   20
!   21  ALL.TXT
!   22  kvasd.dat
!   23  CALL3.TXT

!------------------------------------------------ ftn_init
subroutine ftn_init

  character*1 cjunk
  include 'gcom1.f90'
  include 'gcom2.f90'
  include 'gcom3.f90'
  include 'gcom4.f90'

  i=ptt(nport,0,iptt)                          !Clear the PTT line
  addpfx='    '

  do i=80,1,-1
     if(AppDir(i:i).ne.' ') goto 1
  enddo
1 iz=i
  lenappdir=iz

#ifdef Win32
  open(11,file=appdir(:iz)//'/decoded.txt',status='unknown',               &
       share='denynone',err=910)
#else
  open(11,file=appdir(:iz)//'/decoded.txt',status='unknown',               &
       err=910)
#endif
  endfile 11

#ifdef Win32
  open(12,file=appdir(:iz)//'/decoded.ave',status='unknown',               &
       share='denynone',err=920)
#else
  open(12,file=appdir(:iz)//'/decoded.ave',status='unknown',               &
       err=920)
#endif
  endfile 12

#ifdef Win32
  open(14,file=appdir(:iz)//'/azel.dat',status='unknown',                  &
       share='denynone',err=930)
#else
  open(14,file=appdir(:iz)//'/azel.dat',status='unknown',                  &
       err=930)
#endif

#ifdef Win32
  open(15,file=appdir(:iz)//'/debug.txt',status='unknown',                 &
       share='denynone',err=940)
#else
  open(15,file=appdir(:iz)//'/debug.txt',status='unknown',                 &
       err=940)
#endif

#ifdef Win32
  open(21,file=appdir(:iz)//'/ALL.TXT',status='unknown',                   &
       access='append',share='denynone',err=950)
#else
  open(21,file=appdir(:iz)//'/ALL.TXT',status='unknown',err=950)
  do i=1,9999999
     read(21,*,end=10) cjunk
  enddo
10 continue
#endif

#ifdef Win32
  open(22,file=appdir(:iz)//'/kvasd.dat',access='direct',recl=1024,        &
       status='unknown',share='denynone')
#else
  open(22,file=appdir(:iz)//'/kvasd.dat',access='direct',recl=1024,        &
       status='unknown')
#endif

  return

910 print*,'Error opening DECODED.TXT'
  stop
920 print*,'Error opening DECODED.AVE'
  stop
930 print*,'Error opening AZEL.DAT'
  stop
940 print*,'Error opening DEBUG.TXT'
  stop
950 print*,'Error opening ALL.TXT'
  stop

end subroutine ftn_init
