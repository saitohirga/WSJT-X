subroutine recvpkt(iarg)

! Receive timf2 packets from Linrad and stuff data into array dd().
! (This routine runs in a background thread and will never return.)

  parameter (NSZ=2*60*96000)
  integer*1 userx_no,iusb
  integer*2 nblock,nblock0
  logical first,synced
  real*8 center_freq,d8,buf8
  complex*16 c16,buf16(87)
  integer*2 jd(4)
  real*4 xd(4)
  common/plrscom/center_freq,msec,fqso,iptr,nblock,userx_no,iusb,buf8(174)
  include 'datcom.f90'
  include 'gcom1.f90'
  include 'gcom2.f90'
  equivalence (jd,d8)
  equivalence (xd,c16)
  equivalence (buf8,buf16)
  data nblock0/0/,kb/1/,ns00/99/,first/.true./
  data sqave/0.0/,rxnoise/0.0/,pctblank/0.0/,kbuf/1/,lost_tot/0/
  data multicast0/-99/
  save

1 continue
  call cs_lock('recvpkt')
  call setup_rsocket(multicast)     !Open socket for multicast/unicast data
  call cs_unlock
  k=0
  kk=0
  kxp=0
  kb=1
  nsec0=-999
  fcenter=144.125                   !Default (startup) frequency)
  multicast0=multicast
  ntx=0
  synced=.false.

10 if(multicast.ne.multicast0) go to 1
  call recv_pkt(center_freq)

  if(userx_no.lt.0) then
     nfloat=1
  else
     nfloat=0
  endif

  iz=174
  if(nfloat.ne.0) iz=87

! Should receive a new packet every 174/96000 = 0.0018125 s
  nsec=mod(Tsec,86400.d0)           !Time according to MAP65
  nseclr=msec/1000                  !Time according to Linrad
  fcenter=center_freq
  if(forcefcenter.gt.0.0) fcenter=forcefcenter

! Reset buffer pointers at start of minute.
  ns=mod(nsec,60)
  if(ns.lt.ns00 .and. (lauto+monitoring.ne.0)) then
!     print*,'new minute:',mod(nsec/60,60),ns00,ns,ntx,kb
     if(ntx.eq.0) kb=3-kb
     if(first) kb=1
     k=(kb-1)*60*96000
     kxp=k
     ndone1=0
     ndone2=0
     lost_tot=0
     synced=.true.
     ntx=0
  endif
  ns00=ns

  if(transmitting.eq.1) ntx=1

! Test for buffer full
  if((kb.eq.1 .and. (k+iz).gt.NSMAX) .or.                          &
       (kb.eq.2 .and. (k+iz).gt.2*NSMAX)) go to 20

  if(.not.first) then
! Check for lost packets
     lost=nblock-nblock0-1
     if(lost.ne.0) then
        nb=nblock
        if(nb.lt.0) nb=nb+65536
        nb0=nblock0
        if(nb0.lt.0) nb0=nb0+65536
        lost_tot=lost_tot + lost               ! Insert zeros for the lost data.
!###
!        do i=1,iz*lost
!           k=k+1
!           d8(k)=0
!        enddo
!###
     endif
  endif
  first=.false.
  nblock0=nblock

  tdiff=mod(0.001d0*msec,60.d0)-mod(Tsec,60.d0)
  if(tdiff.lt.-30.) tdiff=tdiff+60.
  if(tdiff.gt.30.) tdiff=tdiff-60.

! Move data into Rx buffer and compute average signal level.
  sq=0.
  do i=1,iz
     k=k+1
     k2=k
     n=1
     if(k.gt.NSMAX) then
        k2=k2-NSMAX
        n=2
     endif

     if(nfloat.eq.0) then
        d8=buf8(i)
        x1=jd(1)
        x2=jd(2)
        x3=jd(3)
        x4=jd(4)
        dd(1,k2,n)=x1
        dd(2,k2,n)=x2
        dd(3,k2,n)=x3
        dd(4,k2,n)=x4
        sq=sq + x1*x1 + x2*x2 + x3*x3 + x4*x4
     else
        c16=buf16(i)
        x1=xd(1)
        x2=xd(2)
        x3=xd(3)
        x4=xd(4)
        dd(1,k2,n)=x1
        dd(2,k2,n)=x2
        dd(3,k2,n)=x3
        dd(4,k2,n)=x4
        sq=sq + x1*x1 + x2*x2 + x3*x3 + x4*x4
     endif
  enddo
  sq=sq/(2.0*iz)
  u=0.001
  if(nfloat.ne.1) u=2.0*u
  sqave=sqave + u*(sq-sqave)
  rxnoise=10.0*log10(sqave) - 20.0            ! Was -48.0
  kxp=k

20 if(nsec.ne.nsec0) then
     nsec0=nsec
     mutch=nseclr/3600
     mutcm=mod(nseclr/60,60)
     mutc=100*mutch + mutcm

! If we have not transmitted in this minute, see if it's time to start FFTs
     if(ntx.eq.0 .and. lauto+monitoring.ne.0) then
        if(ns.ge.nt1 .and. ndone1.eq.0 .and. synced) then
           nutc=mutc
           fcenter=center_freq
           if(forcefcenter.gt.0.0) fcenter=forcefcenter
           kbuf=kb
           kk=k
           ndiskdat=0
           ndone1=1
        endif

! See if it's time to start the full decoding procedure.
        nhsym=(k-(kbuf-1)*60*96000)/17832.9252
        if(ndone1.eq.1 .and. nhsym.ge.279 .and.ndone2.eq.0) then
           kk=k
           nlost=lost_tot                         ! Save stats for printout
           ndone2=1
!           print*,'recvpkt 2:',ns,kb,k
        endif
     endif

!     if(ns.le.5 .or. ns.ge.46) write(*,3001) ns,ndone1,kb,  &
!          kbuf,ntx,kk,tdiff
!3001 format(5i4,i11,f8.2)

  endif
  go to 10

end subroutine recvpkt
