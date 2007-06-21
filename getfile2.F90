subroutine getfile2(fname,len)

#ifdef Win32
  use dflib
#endif

  parameter (NDMAX=661500)  ! =60*11025
  character*(*) fname
  character infile*15

  include 'datcom.f90'
  include 'gcom1.f90'
  include 'gcom2.f90'
  include 'gcom4.f90'

1 if(ndecoding.eq.0) go to 2
#ifdef Win32
  call sleepqq(100)
#else
  call usleep(100*1000)
#endif

  go to 1

2 do i=len,1,-1
     if(fname(i:i).eq.'/' .or. fname(i:i).eq.'\\') go to 10
  enddo
  i=0
10 filename=fname(i+1:)
  ierr=0

  n=8*NSMAX
  monitoring=0
  kbuf=1
#ifdef Win32
!  open(10,file=fname,form='binary',status='old',err=998)
  call rfile3a(fname,id,n,ierr)
  if(ierr.ne.0) then
     print*,'Error opening or reading file: ',fname,ierr
     go to 999
  endif
#else
  call rfile2(fname,id,n,nr)
  if(nr.ne.n) then
     print*,'Error opening or reading file: ',fname,n,nr
     ierr=1002
     go to 999
  endif

#endif

  read(filename(8:11),*) nutc
  ndiskdat=1
  ndecoding=4
  mousebutton=0
  go to 999

998 ierr=1001
999 close(10)
  return
end subroutine getfile2
