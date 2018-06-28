subroutine pack77(msg0,i3,n3,c77)

  use packjt
  character*37 msg,msg0
  character*18 c18
  character*13 w(19)
  character*77 c77
  integer nw(19)
  integer ntel(3)

  msg=msg0
  if(i3.eq.0 .and. n3.eq.5) go to 5

! Convert msg to upper case; collapse multiple blanks; parse into words.
  call split77(msg,nwords,nw,w)
  i3=-1
  n3=-1
  if(msg(1:3).eq.'CQ ' .or. msg(1:3).eq.'DE ' .or. msg(1:4).eq.'QRZ ') go to 100

! Check 0.1 (DXpedition mode)
  call pack77_01(nwords,w,i3,n3,c77)
  if(i3.ge.0) go to 900
! Check 0.2 (EU VHF contest exchange)
  call pack77_02(nwords,w,i3,n3,c77)
  if(i3.ge.0) go to 900

! Check 0.3 and 0.4 (ARRL Field Day exchange)
  call pack77_03(nwords,w,i3,n3,c77)
  if(i3.ge.0) go to 900

! Check 0.5 (telemetry)
5 i0=index(msg,' ')
  c18=msg(1:i0-1)//'                  '
  c18=adjustr(c18)
  ntel=-99
  read(c18,1005,err=6) ntel
1005 format(3z6)
  if(ntel(1).ge.2**23) go to 800
6 if(ntel(1).ge.0 .and. ntel(2).ge.0 .and. ntel(3).ge.0) then
     i3=0
     n3=5
     write(c77,1006) ntel,n3
1006 format(b23.23,2b24.24,b3.3)
     go to 900
  endif

! Check Types 1 and 2 (Standard 77-bit message (type 1) or with "/P" (type 2))
100 call pack77_1(nwords,w,i3,n3,c77)
  if(i3.ge.0) go to 900

! Check Type 3 (ARRL RTTY contest exchange)
  call pack77_3(nwords,w,i3,n3,c77)
  if(i3.ge.0) go to 900

! Check Type 4 (One nonstandard call and one hashed call)
  call pack77_4(nwords,w,i3,n3,c77)
  if(i3.ge.0) go to 900

! It defaults to free text
800 i3=0
  n3=0
  msg(14:)='                        '
  call packtext77(msg(1:13),c77(1:71))
  write(c77(72:77),'(2b3.3)') n3,i3

900  return
end subroutine pack77
