subroutine getfile2(fname,len)

#ifdef CVF
  use dflib
#endif

  character*(*) fname
  real*8 sq

  include 'datcom.f90'
  include 'gcom1.f90'
  include 'gcom2.f90'
  include 'gcom4.f90'

1 if(ndecoding.eq.0) go to 2
#ifdef CVF
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
  ndecoding=4
  monitoring=0
  kbuf=1

  call rfile3a(fname,id,n,ierr)
  if(ierr.ne.0) then
     print*,'Error opening or reading file: ',fname,ierr
     go to 999
  endif

  sq=0.
  ka=0.1*NSMAX
  kb=0.8*NSMAX
  do k=ka,kb
     sq=sq + float(int(id(1,k,1)))**2 + float(int(id(2,k,1)))**2 +    &
          float(int(id(3,k,1)))**2 + float(int(id(4,k,1)))**2
  enddo
  sqave=174*sq/(kb-ka+1)
  rxnoise=10.0*log10(sqave) - 48.0
  read(filename(8:11),*,err=20,end=20) nutc
  go to 30
20 nutc=0

30 ndiskdat=1
  mousebutton=0

999 return
end subroutine getfile2
