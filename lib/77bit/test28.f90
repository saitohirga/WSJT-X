program t8

  character*13 call_0,call_1
  character*1 cerr

  do i=1,999
     read(*,'(a13)',end=999) call_0
     call pack28(call_0,n28)
     call unpack28(n28,call_1)
     cerr=' '
     if(call_0.ne.call_1) cerr='*'
     write(*,1010) call_0,n28,len(trim(call_0)),len(trim(call_1)),cerr,call_1
1010 format(a13,i12,2i5,2x,a1,2x,a13a13)
  enddo
  
999 end program t8
