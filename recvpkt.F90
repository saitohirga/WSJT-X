!---------------------------------------------------- recvpkt
subroutine recvpkt(iarg)

! Receive timf2 packets from Linrad, stuff data into id().
! This routine runs in a background thread and will never return.

#ifdef Win32
  use dflib
#endif

  parameter (NSZ=60*96000)
  real*8 d8(NSZ)
  integer*1 userx_no,iusb
  integer*2 nblock,nblock0
  logical first
  real*8 center_freq,buf8
  common/plrscom/center_freq,msec,fqso,iptr,nblock,userx_no,iusb,buf8(174)
!                     8        4     4      4    2       1       1    1392
  include 'datcom.f90'
  include 'gcom2.f90'
  equivalence (id,d8)
  data nblock0/0/,first/.true./,kb/1/
  save

! Open a socket to receive multicast data from Linrad
  call setup_rsocket
  nreset=-1
  k=0
  npkt=0
  nsec0=-999

10 call recv_pkt(center_freq)
  if((nblock-nblock0).ne.1 .and. .not.first) then
     print*,'Lost packets?',nblock-nblock0,nblock,nblock0
  endif
  first=.false.
  nblock0=nblock

  if(monitoring.eq.1) then

     nsec=msec/1000
     if(mod(nsec,60).eq.1) nreset=1
     if(mod(nsec,60).eq.0 .and. nreset.eq.1) then
! This is the start of a new minute, switch buffers
        nreset=0
        kb=3-kb
        k=0
        if(kb.eq.2) k=NSZ
     endif

     do i=1,174
        k=k+1
        d8(k)=buf8(i)
     enddo

     npkt=npkt+1
     if(nsec.ne.nsec0) then
        mutch=nsec/3600
        mutcm=mod(nsec/60,60)
        mutc=100*mutch + mutcm
        ns=mod(nsec,60)
!     write(*,1010) mutc,ns,0.001*msec,k
!1010 format('UTC:',i5.4,'   ns:',i3,'   t:',f10.3,'   k:',i8)
        nsec0=nsec
     endif

     if(mod(nsec,60).eq.59) then
        kbuf=kb
        nutc=mutc
        ndecoding=1
     endif
  endif
  go to 10

end subroutine recvpkt
