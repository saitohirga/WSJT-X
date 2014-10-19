program jt9code

! Generate simulated data for testing of WSJT-X

  character msg*22,msg0*22,decoded*22,bad*1,msgtype*10
  integer*4 i4tone(85)                     !Channel symbols (values 0-8)
  include 'jt9sync.f90'

  nargs=iargc()
  if(nargs.ne.1) then
     print*,'Usage: jt9code "message"'
     go to 999
  endif

  call getarg(1,msg)
  call fmtmsg(msg,iz)                    !To upper, collapse mult blanks
  msg0=msg                               !Input message

  ichk=0
  call genjt9(msg,ichk,decoded,i4tone,itype)       !Encode message into tone #s

  msgtype=""
  if(itype.eq.1) msgtype="Std Msg"
  if(itype.eq.2) msgtype="Type 1 pfx"
  if(itype.eq.3) msgtype="Type 1 sfx"
  if(itype.eq.4) msgtype="Type 2 pfx"
  if(itype.eq.5) msgtype="Type 2 sfx"
  if(itype.eq.6) msgtype="Free text"

  write(*,1010)
1010 format("Message                 Decoded                 Err"/   &
            "-----------------------------------------------------------------")
  bad=" "
  if(decoded.ne.msg0) bad="*"
  write(*,1020) msg0,decoded,bad,itype,msgtype
1020 format(a22,2x,a22,3x,a1,i3,": ",a10)

  write(*,1030) i4tone
1030 format(/'Channel symbols'/(30i2))

999 end program jt9code
