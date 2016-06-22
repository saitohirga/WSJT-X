program QRA65code

! Provides examples of message packing, bit and symbol ordering,
! Reed Solomon encoding, and other necessary details of the QRA65
! protocol.

  use packjt
  character*22 msg,msg0,msg1,decoded,cok*3,bad*1,msgtype*10
  integer dgen(12),sent(63),dec(12)
  real s3(0:63,1:63)
  include 'testmsg.f90'

  nargs=iargc()
  if(nargs.ne.1) then
     print*,'Usage: qra65code "message"'
     print*,'       qra65code -t'
     go to 999
  endif

  call getarg(1,msg)                     !Get message from command line
  nmsg=1
  if(msg(1:2).eq."-t") nmsg=NTEST

  write(*,1010)
1010 format("     Message                 Decoded                Err? Type             rc"/77("-"))

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
     s3=1.0
     do j=1,63
        do i=0,63
           s3(i,j)=1.0 + 0.1*gran()
        enddo
        k=sent(j)
        s3(k,j)=s3(k,j) + 1.2
     enddo

     call qra65_dec(s3,dec,irc)            !Decode
     decoded="                      "
     if(irc.ge.0) then
        call unpackmsg(dec,decoded)           !Unpack the user message
        call fmtmsg(decoded,iz)
     endif

     bad=" "
     if(decoded.ne.msg0) bad="*"
     write(*,1020) imsg,msg0,decoded,bad,itype,msgtype,irc
1020 format(i2,'.',2x,a22,2x,a22,3x,a1,i3,": ",a13,i3)
  enddo

  if(nmsg.eq.1) then
     write(*,1030) dgen
1030 format(/'Packed message, 6-bit symbols ',12i3) !Display packed symbols

     write(*,1040) sent
1040 format(/'Information-carrying channel symbols'/(i5,20i3))

     write(*,1050) dec
1050 format(/'Received message, 6-bit symbols ',12i3) !Display packed symbols
  endif

999 end program QRA65code
