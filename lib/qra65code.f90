program QRA65code

! Provides examples of message packing, bit and symbol ordering,
! QRA (63,12) encoding, and other necessary details of the QRA65
! protocol.  Also permits simple simulations to measure performance
! on an AWGN channel with secure time and frequency synchronization.

! Return codes from qra65_dec:
!  irc=0    [?    ?    ?] AP0	(decoding with no a-priori information)
!  irc=1    [CQ   ?    ?] AP27
!  irc=2    [CQ   ?     ] AP44
!  irc=3    [CALL ?    ?] AP29
!  irc=4    [CALL ?     ] AP45
!  irc=5    [CALL CALL ?] AP57

  use packjt
  character*22 msg,msg0,msg1,decoded,cok*3,bad*1,msgtype*10,arg*12
  integer dgen(12),sent(63),dec(12)
  real s3(0:63,1:63)
  include 'testmsg.f90'

  nargs=iargc()
  if(nargs.lt.1) then
     print*,'Usage: qra65code "message" [snr2500] [Nrpt]'
     print*,'       qra65code -t [snr2500]'
     go to 999
  endif

  call getarg(1,msg)                     !Get message from command line
  snr2500=10.0
  if(nargs.ge.2) then
     call getarg(2,arg)
     read(arg,*) snr2500
  endif
  sig=sqrt(2.0)*10.0**(0.05*(snr2500+29.7))
  nmsg=1
  nrpt=1
  if(msg(1:2).eq."-t") then
     nmsg=NTEST
  else
     if(nargs.ge.3) then
        call getarg(3,arg)
        read(arg,*) nrpt
     endif
  endif

  write(*,1010)
1010 format("     Message                 Decoded                Err? Type             rc"/77("-"))

  ngood=0
  nbad=0
  do nn=1,nrpt
     do imsg=1,nmsg
        if(nmsg.gt.1) msg=testmsg(imsg)
        call fmtmsg(msg,iz)                    !To upper, collapse mult blanks
        msg0=msg                               !Input message
        call chkmsg(msg,cok,nspecial,flip)     !See if it includes "OOO" report
        msg1=msg                               !Message without "OOO"
        call packmsg(msg1,dgen,itype)          !Pack message into 12 six-bit bytes
        msgtype=""
        if(itype.eq.1) msgtype="Std Msg"
        if(itype.eq.2) msgtype="Type 1 pfx"
        if(itype.eq.3) msgtype="Type 1 sfx"
        if(itype.eq.4) msgtype="Type 2 pfx"
        if(itype.eq.5) msgtype="Type 2 sfx"
        if(itype.eq.6) msgtype="Free text"

        call qra65_enc(dgen,sent)              !Encode using QRA65

! Generate a simulated s3() array with moderately high S/N
        do j=1,63
           do i=0,63
              x=gran()
              y=gran()
              s3(i,j)=x*x + y*y
           enddo
           k=sent(j)
           x=gran() + sig
           y=gran()
           s3(k,j)=x*x + y*y
        enddo

        call qra65_dec(s3,dec,irc)            !Decode
        decoded="                      "
        if(irc.ge.0) then
           call unpackmsg(dec,decoded)           !Unpack the user message
           call fmtmsg(decoded,iz)
        else
           dec=0
        endif

        if(decoded.eq.msg0) then
           ngood=ngood+1
        else
           if(irc.ge.0) nbad=nbad+1
        endif
        ii=imsg
        if(nrpt.gt.1) ii=nn
        write(*,1020) ii,msg0,decoded,itype,msgtype,irc
1020    format(i4,1x,a22,2x,a22,4x,i3,": ",a13,i3)
     enddo

     if(nmsg.eq.1 .and.nrpt.eq.1) then
        write(*,1030) dgen
1030    format(/'Packed message, 6-bit symbols ',12i3) !Display packed symbols

        write(*,1040) sent
1040    format(/'Information-carrying channel symbols'/(i5,20i3))

        write(*,1050) dec
1050    format(/'Received message, 6-bit symbols ',12i3) !Display packed symbols
     endif
  enddo

  if(nrpt.gt.1) then
     write(*,1060) ngood,nrpt,nbad
1060 format('Decoded messages:',i5,'/',i4,'   Undetected errors:',i5)
  endif

999 end program QRA65code
