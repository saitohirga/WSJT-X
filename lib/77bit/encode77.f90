program encode77

  use packjt77
  
  character*80 msg0
  character msg*37,cerr*1
  character*77 c77

  nargs=iargc()
  open(10,file='messages.txt',status='old')
  
  do iline=1,999
     if(nargs.eq.1) then
        call getarg(1,msg0)
     else
        if(iline.eq.1) write(*,1000)
1000    format('i3.n3 Err Message to be encoded                 Decoded message'/ &
             80('-'))
        read(10,1002,end=999) msg0
1002    format(a80)
     endif
     if(msg0(1:1).eq.'$') exit
     if(msg0.eq.'                                     ') cycle
     if(msg0(2:2).eq.'.' .or. msg0(3:3).eq.'.') cycle
     if(msg0(1:3).eq.'---') cycle
     msg0=adjustl(msg0)
     call pack77(msg0(1:37),i3,n3,c77)
     call unpack77(c77,msg)
     cerr=' '
     if(msg.ne.msg0(1:37)) cerr='*'
     if(i3.eq.0) write(*,1004) i3,n3,cerr,msg0(1:37),msg
1004 format(i2,'.',i1,2x,a1,3x,a37,1x,a37)
     if(i3.ge.1) write(*,1005) i3,cerr,msg0(1:37),msg
1005 format(i2,'.',3x,a1,3x,a37,1x,a37)
     if(nargs.eq.1) exit
  enddo

999 end program encode77

include '../chkcall.f90'
