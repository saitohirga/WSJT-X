!---------------------------------------------------- recvpkt
subroutine recvpkt(iarg)

! Receive timf2 packets from Linrad, stuff data into id().
! This routine runs in a background thread and will never return.

!#ifdef Win32
!  use dflib
!#endif

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
  data nblock0/0/,first/.true./,kb/1/,ntx/0/,npkt/0/,nw/0/
  data sqave/0.0/,u/0.001/,rxnoise/0.0/,kbuf/1/
  save

  call setup_rsocket            ! Open socket to receive multicast data
  nreset=-1
  k=0
  nsec0=-999

10 call recv_pkt(center_freq)

  isec=mid_sec()
  imin=isec/60
  if((monitoring.eq.0) .or. (lauto.eq.1 .and. mod(imin,2).eq.(1-TxFirst))) then
     first=.true.
     go to 10
  endif

  lost=nblock-nblock0-1
  nblock0=nblock

  if(lost.ne.0 .and. .not.first) then
!     print*,'Lost packets:',nblock,nblock0,lost
     nlost=nlost + lost               ! Insert zeros for the lost data.
     do i=1,174*lost
        k=k+1
        d8(k)=0
     enddo
  endif
  first=.false.

  nsec=msec/1000
  if(mod(nsec,60).eq.1) nreset=1
  if(mod(nsec,60).eq.0 .and. nreset.eq.1) then
! This is the start of a new minute, switch buffers
     nreset=0
     kb=3-kb
     k=0
     if(kb.eq.2) k=NSMAX
     nlost=0
  endif

  if(kb.eq.1 .and. (k+174).gt.NSMAX) go to 20
  if(kb.eq.2 .and. (k+174).gt.2*NSMAX) go to 20

  sq=0.
  do i=1,174
     k=k+1
     d8(k)=buf8(i)
     sq=sq + float(int(id(1,k,1)))**2 + float(int(id(1,k,1)))**2 +    &
          float(int(id(1,k,1)))**2 + float(int(id(1,k,1)))**2
  enddo
  sqave=sqave + u*(sq-sqave)
  rxnoise=10.0*log10(sqave) - 48.0

  if(mode.eq.'Measur') then
     npkt=npkt+1
     if(npkt.ge.551) then
        npkt=0
        nw=nw+1
        write(11,1000) nw,rxnoise
1000    format(i6,f8.2)
        call flushqqq(11)
        ndecdone=1
        write(24,1000) nw,rxnoise
     endif
  else
     nw=0
  endif

  if(k.lt.1 .or. k.gt.NSZ) then
     print*,'Error in recvpkt: ',k,NSZ,NSMAX
     stop
  endif

20 if(nsec.ne.nsec0) then
     mutch=nsec/3600
     mutcm=mod(nsec/60,60)
     mutc=100*mutch + mutcm
     ns=mod(nsec,60)
     nsec0=nsec
     ntx=ntx+transmitting
     print*,ns,kb,kbuf,k,kk,kkdone

     if(ns.eq.48) then
        nutc=mutc
        kbuf=kb
        kk=k
        print*,'A1',mod(mid_sec(),60),nutc,kk,kbuf,kkdone
     endif
     if(ns.eq.52) then
        nutc=mutc
        kbuf=kb
        kk=k
        ndiskdat=0
        print*,'A2',mod(mid_sec(),60),nutc,kk,kbuf,kkdone
     endif
  endif
  go to 10

end subroutine recvpkt
