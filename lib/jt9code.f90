program jt9code

! Generate simulated data for testing of WSJT-X

  character*22 testmsg(20)
  character msg*22,msg0*22,decoded*22,bad*1,msgtype*10
  integer*4 i4tone(85)                     !Channel symbols (values 0-8)
  include 'jt9sync.f90'

  nargs=iargc()
  if(nargs.ne.1) then
     print*,'Usage: jt9code "message"'
     print*,'       jt9code -t'
     go to 999
  endif

  call getarg(1,msg)
  nmsg=1
  if(msg(1:2).eq."-t") then
     testmsg(1)="KA1ABC WB9XYZ EN34"
     testmsg(2)="KA1ABC WB9XYZ RO"
     testmsg(3)="KA1ABC WB9XYZ -21"
     testmsg(4)="KA1ABC WB9XYZ R-19"
     testmsg(5)="KA1ABC WB9XYZ RRR"
     testmsg(6)="KA1ABC WB9XYZ 73"
     testmsg(7)="KA1ABC WB9XYZ"
     testmsg(8)="ZL/KA1ABC WB9XYZ"
     testmsg(9)="KA1ABC ZL/WB9XYZ"
     testmsg(10)="KA1ABC/4 WB9XYZ"
     testmsg(11)="KA1ABC WB9XYZ/4"
     testmsg(12)="CQ ZL4/KA1ABC"
     testmsg(13)="DE ZL4/KA1ABC"
     testmsg(14)="QRZ ZL4/KA1ABC"
     testmsg(15)="CQ WB9XYZ/VE4"
     testmsg(16)="HELLO WORLD"
     testmsg(17)="ZL4/KA1ABC 73"
     testmsg(18)="KA1ABC XL/WB9XYZ"
     testmsg(19)="KA1ABC WB9XYZ/W4"
     testmsg(20)="123456789ABCDEFGH"
     nmsg=20
  endif

  write(*,1010)
1010 format("Message                 Decoded                 Err?"/   &
            "-----------------------------------------------------------------")
  do imsg=1,nmsg
     if(nmsg.gt.1) msg=testmsg(imsg)
     call fmtmsg(msg,iz)                    !To upper, collapse mult blanks
     msg0=msg                               !Input message

     ichk=0
     call genjt9(msg,ichk,decoded,i4tone,itype)   !Encode message into tone #s

     msgtype=""
     if(itype.eq.1) msgtype="Std Msg"
     if(itype.eq.2) msgtype="Type 1 pfx"
     if(itype.eq.3) msgtype="Type 1 sfx"
     if(itype.eq.4) msgtype="Type 2 pfx"
     if(itype.eq.5) msgtype="Type 2 sfx"
     if(itype.eq.6) msgtype="Free text"

     bad=" "
     if(decoded.ne.msg0) bad="*"
     write(*,1020) msg0,decoded,bad,itype,msgtype
1020 format(a22,2x,a22,3x,a1,i3,": ",a10)
  enddo

  if(nmsg.eq.1) write(*,1030) i4tone
1030 format(/'Channel symbols'/(30i2))

999 end program jt9code
