program t1

  character*22 msg
  complex c3(0:4096-1)
  complex c5(0:4096-1)

  do i=1,999
     read(51,end=999) nutc,nsnr,xdt,nfreq,msg,c3,c5
     write(*,1010) nutc,nsnr,xdt,nfreq,msg
1010 format(2i6,f7.1,i6,2x,a22)
  enddo

999 end program t1
