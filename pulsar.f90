program pulsar

!  Receives timf2 data from Linrad and saves it for pulsar processing.

  parameter (NSPP=174)
  logical first
  integer*1 userx_no,iusb
  integer*2 id
  integer*2 nblock,nblock0
  integer*2 id2(1000)
  real*8 center_freq
  common/plrscom/center_freq,msec,fselect,iptr,nblock,userx_no,iusb,id(4,NSPP)
!                     8        4     4      4    2       1       1    1392
  data first/.true./,nblock0/0/,sqave/0.0/,u/0.001/
  save

  call setup_rsocket

  k=0

10 call recv_pkt(center_freq)
  lost=nblock-nblock0-1
  if(lost.ne.0 .and. .not.first) print*,'Lost packets:',lost,nblock,nblock0
  nblock0=nblock

  sq=0.
  do i=1,NSPP
     sq=sq + float(id(1,i))**2 + float(id(2,i))**2 +                      &
          float(id(3,i))**2 + float(id(4,i))**2
  enddo
  sqave=sqave + u*(sq-sqave)
  rxnoise=10.0*log10(sqave) - 48.0

  k=k+1
  id2(k)=0.001*sq
  if(k.eq.1000) then
     write(*,1000) center_freq,0.001*msec,sqave,rxnoise,id2(1)
     write(13,1000) center_freq,0.001*msec,sqave,rxnoise,id2(1)
1000 format(f7.3,f11.3,f10.0,f8.2,i8)
     write(12) center_freq,msec1,id2
     call flush(12)
     call flush(13)
     k=0
  endif

  go to 10

end program pulsar

! To compile: % gfortran -o pulsar pulsar.f90 plrr_subs.c
