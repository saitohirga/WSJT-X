program plrr

!  Pseudo-Linrad "Receive" program

  integer*1 userx_no,iusb
  integer*2 nblock,nblock0
  real*8 center_freq,buf8
  logical first
  common/plrscom/center_freq,msec,fselect,iptr,nblock,userx_no,iusb,buf8(174)
  data first/.true./

  call setup_rsocket
  ns0=-99
  nlost=0

10 call recv_pkt(center_freq)

  lost=nblock-nblock0-1
  if(lost.ne.0 .and. .not.first) then
     nb=nblock
     if(nb.lt.0) nb=nb+65536
     nb0=nblock0
     if(nb0.lt.0) nb0=nb0+65536
     print*,'Lost packets:',nb,nb0,lost
     nlost=nlost + lost               ! Insert zeros for the lost data.
!     do i=1,174*lost
!        k=k+1
!        d8(k)=0
!     enddo
     first=.false.
     nlost=nlost+lost
  endif
  nblock0=nblock

  ns=mod(msec/1000,60)
  if(ns.ne.ns0) write(*,1010) ns,center_freq,0.001*msec,sec_midn(),nlost
1010 format('ns:',i3,'   f0:',f10.3,'   t1:',f10.3,'   t2:',f10.3,i8)
  ns0=ns
  go to 10

end program plrr

! To compile: % gfortran -o plrr plrr.f90 sec_midn.F90 plrr_subs.c
