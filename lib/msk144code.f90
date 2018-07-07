program msk144code

! Provides examples of message packing, bit and symbol ordering,
! LDPC encoding, and other necessary details of the MSK144 protocol.

  use packjt
  character msg*37,msgsent*37,decoded,bad*1,msgtype*13,mygrid*6
  integer*4 i4tone(144)
  logical*1 bcontest
  include 'testmsg.f90'
  data mygrid/'FN20qi'/

  nargs=iargc()
  if(nargs.ne.1) then
     print*,'Usage: msk144code "message"'
     print*,'       msk144code -t'
     print*,' '
     print*,'Examples:'
     print*,'       msk144code "KA1ABC WB9XYZ EN37"'
     print*,'       msk144code "<KA1ABC WB9XYZ> R-03"'
     print*,'       msk144code "KA1ABC WB9XYZ R EN37"'
     go to 999
  endif

  call getarg(1,msg)
  nmsg=1
  if(msg(1:2).eq."-t") then
     testmsg(NTEST+1)="<KA1ABC WB9XYZ> -03"
     testmsg(NTEST+2)="<KA1ABC WB9XYZ> R+03" 
     testmsg(NTEST+3)="<KA1ABC WB9XYZ> RRR" 
     testmsg(NTEST+4)="<KA1ABC WB9XYZ> 73" 
     testmsg(NTEST+5)="KA1ABC WB9XYZ R EN37"
     nmsg=NTEST+5
  endif

  write(*,1010)
1010 format("     Message                 Decoded                Err? Type"/   &
            74("-"))
  do imsg=1,nmsg
     if(nmsg.gt.1) msg=testmsg(imsg)
     call fmtmsg(msg,iz)                !To upper case, collapse multiple blanks
     i1=len(trim(msg))-5
     bcontest=.false.
     if(msg(i1:i1+1).eq.'R ') bcontest=.true.
     ichk=0
     call genmsk_128_90(msg,mygrid,ichk,bcontest,msgsent,i4tone,itype)

     msgtype=""
     if(itype.eq.1) msgtype="Std Msg"
     if(itype.eq.2) msgtype="Type 1 prefix"
     if(itype.eq.3) msgtype="Type 1 suffix"
     if(itype.eq.4) msgtype="Type 2 prefix"
     if(itype.eq.5) msgtype="Type 2 suffix"
     if(itype.eq.6) msgtype="Free text"
     if(itype.eq.7) msgtype="Hashed calls"

     bad=" "
     if(msgsent.ne.msg) bad="*"
     write(*,1020) imsg,msg,msgsent,bad,itype,msgtype
1020 format(i2,'.',2x,a37,2x,a37,3x,a1,i3,": ",a13)
  enddo

  if(nmsg.eq.1) then
     n=144
     if(msg(1:1).eq."<") n=40
     write(*,1030) i4tone(1:n)
1030 format(/'Channel symbols'/(72i1))
  endif

999 end program msk144code
