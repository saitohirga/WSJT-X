program encode77

  character msg*37,msg0*37,cerr*1
  character*77 c77

  open(10,file='msgtypes.txt',status='old')

! Skip over first two lines
  read(10,1001) cerr
  read(10,1001) cerr
1001 format(a1)
  
  do iline=1,999
     read(10,1002,end=999) i3a,n3a,msg0
1002 format(i1,i4,1x,a37)
     i3=i3a
     n3=n3a
     if(i3a.gt.1 .or. n3a.gt.5) cycle
     call pack77(msg0,i3,n3,c77)
     call unpack77(c77,msg)
     cerr=' '
     if(i3a.ne.i3 .or. n3a.ne.n3 .or. msg.ne.msg0) cerr='*'
     write(*,1004) i3,n3,cerr,msg0,msg
1004 format(i1,'.',i1,1x,a1,1x,a37,1x,a37)
  enddo

999 end program encode77

include '../chkcall.f90'
include 'pack77.f90'
include 'unpack77.f90'
include 'pack28.f90'
include 'unpack28.f90'
include 'split77.f90'
include 'pack77_01.f90'
include 'pack77_02.f90'
include 'pack77_03.f90'
include 'pack77_1.f90'
include 'chk77_2.f90'
include 'chk77_3.f90'
include 'packtext77.f90'
include 'unpacktext77.f90'
