function stdmsg(msg0)

  ! Returns .true. if msg0 a standard "JT-style" message
  
  ! itype
  !  1     Standard 72-bit structured message
  !  2     Type 1 prefix
  !  3     Type 1 suffix
  !  4     Type 2 prefix
  !  5     Type 2 suffix
  !  6     Free text
  !  7     Hashed calls (MSK144 short format)

  ! i3.n3
  !  0.0   Free text
  !  0.1   DXpeditiion mode
  !  0.2   EU VHF Contest
  !  0.3   ARRL Field Day <=16 transmitters
  !  0.4   ARRL Field Day >16 transmitters
  !  0.5   telemetry
  !  0.6
  !  0.7
  !  1     Standard 77-bit structured message (optional /R)
  !  2     EU VHF Contest (optional /P)
  !  3     ARRL RTTY Contest
  !  4     Nonstandard calls

  use iso_c_binding, only: c_bool
  use packjt
  character*37 msg0,msg1,msg
  integer dat(12)
  logical(c_bool) :: stdmsg

  msg1=msg0
  i0=index(msg1,' OOO ')
  if(i0.gt.10) msg1=msg0(1:i0)
  call packmsg(msg0,dat,itype)
  call unpackmsg(dat,msg)
  msg(23:37)='               '
  stdmsg=(msg(1:22).eq.msg1(1:22)) .and. (itype.ge.0) .and. (itype.ne.6)
  if(.not.stdmsg) then
     call parse77(msg1,i3,n3)
     if(i3.gt.0 .or. n3.gt.0) stdmsg=.true.
  endif

  return
end function stdmsg
