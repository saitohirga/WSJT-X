program plrr

!  Pseudo-Linrad "Receive" program

  integer*1 userx_no,iusb
  integer*2 nblock
  real*8 center_freq,buf8
  common/plrscom/center_freq,msec,fselect,iptr,nblock,userx_no,iusb,buf8(174)
!                     8        4     4      4    2       1       1    1392

  call setup_rsocket

  npkt=0

10 call recv_pkt(center_freq)
  npkt=npkt+1
  if(mod(npkt,1000).eq.0) write(*,1010) npkt,center_freq,0.001*msec,fselect
1010 format('npkt:',i10,'   f0:',f8.3,'   t:',f10.3,'   fselect:',f10.3)
  go to 10

end program plrr

! To compile: % gfortran -o plrr plrr.f90 plrr_subs.c
