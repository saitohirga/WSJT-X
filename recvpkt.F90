!---------------------------------------------------- recvpkt
subroutine recvpkt(iarg)

! Receive timf2 packets from Linrad, stuff data into id().
! This routine runs in a background thread and will never return.

#ifdef Win32
  use dflib
#endif

  parameter (NSZ=2*60*96000)
  real*8 d8(NSZ)
  integer*1 userx_no,iusb
  integer*2 nblock,nblock0
  logical first
  real*8 center_freq,buf8
  common/plrscom/center_freq,msec,fqso,iptr,nblock,userx_no,iusb,buf8(174)
!                     8        4     4      4    2       1       1    1392
  include 'datcom.f90'
  include 'gcom1.f90'
  include 'gcom2.f90'
  equivalence (id,d8)
  data nblock0/0/,first/.true./,kb/1/,ntx/0/,npkt/0/,nw/0/
  data sqave/0.0/,u/0.001/,rxnoise/0.0/
  save

! Open a socket to receive multicast data from Linrad
  call setup_rsocket
  nreset=-1
  k=0
  nsec0=-999

10 call recv_pkt(center_freq)
  if(monitoring.eq.1) then
     lost=nblock-nblock0-1
     nblock0=nblock

     if(lost.ne.0 .and. .not.first) then
!        print*,'Lost packets?',nblock,nblock0,lost,rxnoise,mode
!  Fill in zeros for the lost data.
        nlost=nlost + lost
        do i=1,174*lost
           k=k+1
           d8(k)=0
        enddo
     endif
     first=.false.

!###
!     kbuf=kb
!     kk=k
!###

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

     if(transmitting.eq.0) then
        sq=0.
        do i=1,174
           k=k+1
           d8(k)=buf8(i)
           sq=sq + float(id(1,k,1))**2 + float(id(1,k,1))**2 +      &
                float(id(1,k,1))**2 + float(id(1,k,1))**2
        enddo
        sqave=sqave + u*(sq-sqave)
        rxnoise=10.0*log10(sqave) - 48.0

        if(mode.eq.'Measur') then
           npkt=npkt+1
           if(npkt.ge.551) then
              npkt=0
              nw=nw+1
              write(11,1000) nw,rxnoise
1000          format(i6,f8.2)
              call flushqqq(11)
              ndecdone=1
              write(24,1000) nw,rxnoise
           endif
        else
           nw=0
        endif

     else
!  We're transmitting, zero out this packet.
        do i=1,174
           k=k+1
           d8(k)=0.d0
        enddo
     endif
     if(k.lt.1 .or. k.gt.NSZ) then
        print*,'Error in recvpkt: ',k,NSZ,NSMAX
        stop
     endif

20   if(nsec.ne.nsec0) then
        mutch=nsec/3600
        mutcm=mod(nsec/60,60)
        mutc=100*mutch + mutcm
        ns=mod(nsec,60)
!     write(*,1010) mutc,ns,0.001*msec,k,rxnoise
!1010 format('UTC:',i5.4,'   ns:',i3,'   t:',f10.3,'   k:',i8)
        nsec0=nsec
        ntx=ntx+transmitting
        if(mod(nsec,60).eq.52) then
           kk=k
           kbuf=kb
           nutc=mutc
           klost=nlost
!           if(ntx.lt.20) then
!              newdat=1
!              ndecoding=1
!           endif
           ntx=0
        endif
     endif

  endif
  go to 10

end subroutine recvpkt
