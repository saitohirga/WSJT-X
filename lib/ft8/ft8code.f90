program ft8code

! Provides examples of message packing, LDPC(144,87) encoding, bit and
! symbol ordering, and other details of the FT8 protocol.

  use packjt
  use crc
  include 'ft8_params.f90'               !Set various constants
  include 'ft8_testmsg.f90'
  parameter (NWAVE=NN*NSPS)
  
  character*40 msg,msgchk
  character*37 msg37
  character*6 c1,c2
  character*9 comment
  character*22 msgsent,message
  character*6 mygrid6
  character bad*1,msgtype*10
  character*87 cbits
  logical bcontest
  integer itone(NN)
  integer dgen(12)
  integer*1 msgbits(KK),decoded(KK),decoded0(KK)
  data mygrid6/'EM48  '/

! Get command-line argument(s)
  nargs=iargc()
  if(nargs.ne.1 .and. nargs.ne.3) then
     print*
     print*,'Program ft8code:  Provides examples of message packing, ',       &
          'LDPC(174,87) encoding,'
     print*,'bit and symbol ordering, and other details of the FT8 protocol.'
     print*
     print*,'Usage: ft8code [-c grid] "message"  # Results for specified message'
     print*,'       ft8code -t                   # Examples of all message types'
     go to 999
  endif

  bcontest=.false.
  call getarg(1,msg)                    !Message to be transmitted
  if(len(trim(msg)).eq.2 .and. msg(1:2).eq.'-t') then
     testmsg(NTEST+1)='KA1ABC RR73; WB9XYZ <KH1/KH7Z> -11'
     nmsg=NTEST+1
  else if(len(trim(msg)).eq.2 .and. msg(1:2).eq.'-c') then
     bcontest=.true.
     call getarg(2,mygrid6)
     call getarg(3,msg)
     msgchk=msg
     nmsg=1
  else
     msgchk=msg
     call fmtmsg(msgchk,iz)          !To upper case; collapse multiple blanks
     nmsg=1
  endif

  write(*,1010)
1010 format("    Message                Decoded              Err? Type"/76("-"))

  do imsg=1,nmsg
     if(nmsg.gt.1) msg=testmsg(imsg)
     call fmtmsg(msg,iz)               !To upper case, collapse multiple blanks
     msgchk=msg
     
! Generate msgsent, msgbits, and itone
     if(index(msg,';').le.0) then
        call packmsg(msg(1:22),dgen,itype,bcontest)
        msgtype=""
        if(itype.eq.1) msgtype="Std Msg"
        if(itype.eq.2) msgtype="Type 1 pfx"
        if(itype.eq.3) msgtype="Type 1 sfx"
        if(itype.eq.4) msgtype="Type 2 pfx"
        if(itype.eq.5) msgtype="Type 2 sfx"
        if(itype.eq.6) msgtype="Free text"
        i3bit=0
        call genft8(msg(1:22),mygrid6,bcontest,i3bit,msgsent,msgbits,itone)
     else
        call foxgen_wrap(msg,msgbits,itone)
        i3bit=1
     endif
     decoded=msgbits
     i3bit=4*decoded(73) + 2*decoded(74) + decoded(75)
     iFreeText=decoded(57)
     decoded0=decoded
     if(i3bit.eq.1) decoded(57:)=0
     call extractmessage174(decoded,message,ncrcflag)
     decoded=decoded0

     if(i3bit.eq.0) then
        if(bcontest) call fix_contest_msg(mygrid6,message)
        bad=" "
        comment='         '
        if(itype.ne.6 .and. message.ne.msgchk) bad="*"
        if(itype.eq.6 .and. message(1:13).ne.msgchk(1:13)) bad="*"
        if(itype.eq.6 .and. len(trim(msgchk)).gt.13) comment='truncated'
        write(*,1020) imsg,msgchk,message,bad,i3bit,itype,msgtype,comment
1020    format(i2,'.',1x,a22,1x,a22,1x,a1,2i2,1x,a10,1x,a9)
     else
        write(cbits,1001) decoded
1001    format(87i1)
        read(cbits,1002) nrpt
1002    format(66x,b6)
        irpt=nrpt-30
        i1=index(message,' ')
        i2=index(message(i1+1:),' ') + i1
        c1=message(1:i1)//'   '
        c2=message(i1+1:i2)//'   '
        msg37=c1//' RR73; '//c2//' <...>    '
        write(msg37(35:37),1003) irpt
1003    format(i3.2)
        if(msg37(35:35).ne.'-') msg37(35:35)='+'
        iz=len(trim(msg37))
        do iter=1,10                           !Collapse multiple blanks into one
           ib2=index(msg37(1:iz),'  ')
           if(ib2.lt.1) exit
           msg37=msg37(1:ib2)//msg37(ib2+2:)
           iz=iz-1
        enddo
 
        write(*,1021) imsg,msgchk,msg37
1021    format(i2,'.',1x,a40,1x,a37)
     endif

  enddo

  if(nmsg.eq.1) then
     write(*,1030) msgbits(1:56)
1030 format(/'Call1: ',28i1,'    Call2: ',28i1)
     write(*,1032) msgbits(57:72),msgbits(73:75),msgbits(76:87)
1032 format('Grid:  ',16i1,'   3Bit: ',3i1,'    CRC12: ',12i1)
     write(*,1034) itone
1034 format(/'Channel symbols:'/79i1)
  endif

999 end program ft8code
