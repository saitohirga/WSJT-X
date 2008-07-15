subroutine recvpkt(iarg)

! Receive timf2 packets from Linrad and stuff data into array id().
! (This routine runs in a background thread and will never return.)

  parameter (NSZ=2*60*96000)
  real*8 d8(NSZ)
  integer*1 userx_no,iusb
  integer*2 nblock,nblock0
  integer txnow
  logical first
  real*8 center_freq,buf8
  common/plrscom/center_freq,msec,fqso,iptr,nblock,userx_no,iusb,buf8(174)
  include 'datcom.f90'
  include 'gcom1.f90'
  include 'gcom2.f90'
  equivalence (id,d8)
  data nblock0/0/,first/.true./,kb/1/,npkt/0/,nw/0/
  data sqave/0.0/,u/0.001/,rxnoise/0.0/,kbuf/1/,lost_tot/0/
  data multicast0/-99/
  save

1 call setup_rsocket(multicast)     !Open socket for multicast/unicast data
  nreset=-1
  k=0
  nsec0=-999
  fcenter=144.125                   !Default (startup) frequency)
  multicast0=multicast

10 if(multicast.ne.multicast0) go to 1

  call recv_pkt(center_freq)
  fcenter=center_freq

! Wait for an even minute to start accepting Rx data.
  if(nsec0.eq.-999) then
     if(mod(msec/1000,60).ne.0) go to 10
     nsec0=-998
  endif

  isec=sec_midn()
  imin=isec/60
  if((monitoring.eq.0) .or. (lauto.eq.1 .and. mod(imin,2).eq.(1-TxFirst))) then
     first=.true.

! If we're transmitting and were previously receiving in this minute,
! switch buffers to prepare for the next Rx minute.
     if(lauto.eq.1 .and. mod(imin,2).eq.(1-TxFirst) .and. nreset.eq.1) then
        nreset=0
        kb=3-kb
        k=0
        if(kb.eq.2) k=NSMAX
        lost_tot=0
        ndone1=0
        ndone2=0
     endif
     go to 10
  endif

! If we get here, we're in Rx mode
  lost=nblock-nblock0-1
  if(lost.ne.0 .and. .not.first) then
     nb=nblock
     if(nb.lt.0) nb=nb+65536
     nb0=nblock0
     if(nb0.lt.0) nb0=nb0+65536
     lost_tot=lost_tot + lost               ! Insert zeros for the lost data.
     do i=1,174*lost
        k=k+1
        d8(k)=0
     enddo
  endif
  nblock0=nblock

  nsec=msec/1000
  if(mod(nsec,60).eq.1) nreset=1

! If this is the start of a new minute, switch buffers
  if(mod(nsec,60).eq.0 .and. nreset.eq.1) then
     nreset=0
     kb=3-kb
     k=0
     if(kb.eq.2) k=NSMAX
     lost_tot=0
     ndone1=0
     ndone2=0
  endif

  if(kb.eq.1 .and. (k+174).gt.NSMAX) go to 20
  if(kb.eq.2 .and. (k+174).gt.2*NSMAX) go to 20

  sq=0.
  do i=1,174
     k=k+1
     d8(k)=buf8(i)
     k2=k
     n=1
     if(k.gt.NSMAX) then
        k2=k2-NSMAX
        n=2
     endif
     sq=sq + float(int(id(1,k2,n)))**2 + float(int(id(1,k2,n)))**2 +    &
          float(int(id(1,k2,n)))**2 + float(int(id(1,k2,n)))**2
  enddo
  sqave=sqave + u*(sq-sqave)
  rxnoise=10.0*log10(sqave) - 48.0
  kxp=k

  if(k.lt.1 .or. k.gt.NSZ) then
     print*,'Error in recvpkt: ',k,NSZ,NSMAX
     stop
  endif

! The following may be a bad idea because it uses non-reentrant Fortran I/O ???
  if(mode.eq.'Measur') then
     npkt=npkt+1
     if(npkt.ge.551) then
        npkt=0
        nw=nw+1
        rewind 11
        write(11,1000) nw,rxnoise
1000    format(i6,f8.2)
        write(11,*) '$EOF'
        call flushqqq(11)
        ndecdone=1
        write(24,1000) nw,rxnoise
     endif
  else
     nw=0
  endif

20 if(nsec.ne.nsec0) then
     mutch=nsec/3600
     mutcm=mod(nsec/60,60)
     mutc=100*mutch + mutcm
     ns=mod(nsec,60)
     nsec0=nsec

! See if it's time to start FFTs
     if(ns.ge.nt1 .and. ndone1.eq.0) then
        nutc=mutc
        fcenter=center_freq
        kbuf=kb
        kk=k
        ndiskdat=0
        ndone1=1
     endif

! See if it's time to start second stage of processing
     if(ns.ge.nt2 .and. ndone2.eq.0) then
        kk=k
        ndone2=1
        nlost=lost_tot                         ! Save stats for printout
     endif
  endif
  first=.false.
  go to 10

end subroutine recvpkt
