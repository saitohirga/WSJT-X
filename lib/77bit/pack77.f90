subroutine pack77(msg,i3,n3,c77)

  use packjt
  character*37 msg
!  character*22 msg22
  character*13 w(19)
  character*77 c77
  integer nw(19)

! Convert msg to upper case; collapse multiple blanks; parse into words.
  call split77(msg,nwords,nw,w)
  i3=-1
  n3=-1
  
! Check 0.1 (DXpedition mode)
  call pack77_01(nwords,w,i3,n3,c77)
  if(i3.ge.0) go to 900
! Check 0.2 (EU VHF contest exchange)
  call pack77_02(nwords,w,i3,n3,c77)
  if(i3.ge.0) go to 900

! Check 0.3 and 0.4 (ARRL Field Day exchange)
  call pack77_03(nwords,w,i3,n3,c77)
  if(i3.ge.0) go to 900
  

! Check Types 1 and 4 (Standard 77-bit message (type 1) or with "/P" (type 4))
  call chk77_1(nwords,w,i3,n3)
  if(i3.ge.0) go to 900

! Check Type 2 (ARRL RTTY contest exchange)
  call chk77_2(nwords,w,i3,n3)
  if(i3.ge.0) go to 900

! Check Type 3 (One nonstandard call and one hashed call)
  call chk77_3(nwords,w,i3,n3)
  if(i3.ge.0) go to 900

! By default, it's free text
  i3=0
  n3=0
  msg(14:)='                        '
  call packtext77(msg(1:13),c77(1:71))
  write(c77(72:77),'(2b3.3)') n3,i3
  
900 continue

  return
end subroutine pack77
