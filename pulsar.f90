program pulsar

!  Receives timf2 data from Linrad and saves it for pulsar processing.

  parameter (NSPP=174)                     !Samples per UDP packet
  integer*1 userx_no,iusb
  integer*2 id
  integer*2 nblock
  integer*2 id2(1000)
  integer nt(8)
  character pname*12,cdate*8,ctime*12,czone*8
  character*40 fname20,fname21
  real*8 center_freq,tsec
  common/plrscom/center_freq,msec,fselect,iptr,nblock,userx_no,iusb,id(4,NSPP)
!                     8        4     4      4    2       1       1    1392
  data nb0/0/,sqave/0.0/,u/0.001/,nw/0/
  save

  nargs=iargc()
  if(nargs.ne.1) then
     print*,'Usage: pulsar <pname>'
     go to 999
  endif
  call getarg(1,pname)

! nt: year, month, day, time difference in minutes, hours, minutes, 
! seconds, and milliseconds. 
  call date_and_time(cdate,ctime,czone,nt)

  write(fname20,1001) nt(1)-2000,nt(2),nt(3),nt(5),nt(6),nt(7)
1001 format(3i2.2,'_',3i2.2,'.raw')
  open(20,file=fname20,access='stream',status='unknown')
  write(20) cdate,ctime,czone,nt,pname       !Write header
!  write(fname21,1002) nt(1)-2000,nt(2),nt(3),nt(5),nt(6),nt(7)
!1002 format(3i2.2,'_',3i2.2,'.sq')
!  open(21,file=fname21,access='stream',status='unknown')
!  write(21) cdate,ctime,czone,nt,pname       !Write header

  call setup_rsocket                         !Prepare to receive UDP packets
  k=0

10 call recv_pkt(center_freq)
  nb=nblock
  if(nb.lt.0) nb=nb+65536
  lost=nb-nb0-1
  if(lost.ne.0 .and. nb0.ne.0) print*,'Lost packets:',lost,nb,nb0

  write(20) id                               !Write raw data
  sq=0.
  do i=1,NSPP
     sq=sq + float(int(id(1,i)))**2 + float(int(id(2,i)))**2 +      &
          float(int(id(3,i)))**2 + float(int(id(4,i)))**2
  enddo
  sqave=sqave + u*(sq-sqave)
  rxnoise=10.0*log10(sqave) - 48.0

  k=k+1
  id2(k)=0.001*sq
  if(k.eq.1000) then
     tsec=0.001d0*msec
     nsec=tsec
     ih=nsec/3600
     im=mod(nsec/60,60)
     is=mod(nsec,60)
     nw=nw+1
     write(*,1000) nw,center_freq,ih,im,is,nblock,sqave,rxnoise,id2(1)
!     write(13,1000) nw,center_freq,0.001*msec,nblock,sqave,rxnoise,id2(1)
1000 format(i10,f7.3,i4,2i3.2,i7,f10.0,f8.2,i8)
     write(21) id2

     call flush(20)
     call flush(21)
     k=0
  endif

  nb0=nb
  go to 10

999 end program pulsar

! To compile: % gfortran -o pulsar pulsar.f90 plrr_subs.c
