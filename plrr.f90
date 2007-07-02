program plrr

!  Pseudo-Linrad "Receive" program

  integer*1 userx_no,iusb
  integer*2 nblock
  real*8 center_freq,buf8
  common/plrscom/center_freq,msec,fselect,iptr,nblock,userx_no,iusb,buf8(174)

  call setup_rsocket
  ns0=-99

10 call recv_pkt(center_freq)
  ns=mod(msec/1000,60)
  if(ns.ne.ns0) write(*,1010) ns,center_freq,0.001*msec,sec_midn()
1010 format('ns:',i3,'   f0:',f10.3,'   t1:',f10.3,'   t2:',f10.3)
  ns0=ns
  go to 10

end program plrr

! To compile: % gfortran -o plrr plrr.f90 plrr_subs.c
