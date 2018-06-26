subroutine pack28(c13,n28)

! Pack a special token, a 24-bit hash code, or a valid base call into a 28-bit
! integer.

  parameter (NTOKENS=4874084,N24=16777216)
  integer nc(6)
  character*13 c13
  character*6 callsign
  character*37 c1
  character*36 c2
  character*10 c3
  character*27 c4
  data c1/' 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'/
  data c2/'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'/
  data c3/'0123456789'/
  data c4/' ABCDEFGHIJKLMNOPQRSTUVWXYZ'/
  data nc/37,36,19,27,27,27/

  n28=0
  callsign=c13(1:6)
  
! Work-around for Swaziland prefix:
  if(c13(1:4).eq.'3DA0') callsign='3D0'//c13(5:7)

! Work-around for Guinea prefixes:
  if(c13(1:2).eq.'3X' .and. c13(3:3).ge.'A' .and.          &
       c13(3:3).le.'Z') callsign='Q'//c13(3:6)

!  if(callsign(1:3).eq.'CQ ') then
!     n28=1
!     if(callsign(4:4).ge.'0' .and. callsign(4:4).le.'9' .and.        &
!          callsign(5:5).ge.'0' .and. callsign(5:5).le.'9' .and.      &
!          callsign(6:6).ge.'0' .and. callsign(6:6).le.'9') then
!        read(callsign(4:6),*) nfreq
!        n28=3 + nfreq
!     endif
!     return
!  else if(callsign(1:4).eq.'QRZ ') then
!     n28=2
!     return
!  else if(callsign(1:3).eq.'DE ') then
!     n28=267796945
!     return
!  endif

! We have a standard callsign
  n=len(trim(callsign))
  callsign=adjustr(callsign)
  n28=index(c1,callsign(1:1))-1
  n28=n28*nc(2) + index(c2,callsign(2:2)) - 1
  n28=n28*nc(3) + index(c3,callsign(3:3)) - 1
  n28=n28*nc(4) + index(c4,callsign(4:4)) - 1
  n28=n28*nc(5) + index(c4,callsign(5:5)) - 1
  n28=n28*nc(6) + index(c4,callsign(6:6)) - 1
  n28=n28 + NTOKENS + N24

     
  return
end subroutine pack28
