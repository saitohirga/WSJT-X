program t2

  character msg*37,msg0*37,cerr*1

  open(10,file='msgtypes.txt',status='old')

! Skip over first two lines
  read(10,1001) cerr
  read(10,1001) cerr
1001 format(a1)
  
  do iline=1,999
     read(10,1002,end=999) i3,n3,msg
1002 format(i1,i4,1x,a37)
     msg0=msg
     call parse77(msg,i3a,n3a)
     cerr=' '
     if(i3a.ne.i3 .or. n3a.ne.n3 .or. msg.ne.msg0) cerr='*'
     write(*,1004) i3,n3,i3a,n3a,cerr,msg
1004 format(i1,3i3,2x,a1,2x,a37)
  enddo

999 end program t2

include 'parse77.f90'
include '../chkcall.f90'
