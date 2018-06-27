subroutine pack77_1(nwords,w,i3,n3,c77)
! Check Type 1 (Standard 77-bit message) and Type 2 (ditto, with a "/P" call)

  parameter (MAXGRID4=32400)
  character*13 w(19),c13
  character*77 c77
  character*6 bcall_1,bcall_2
  character*4 grid4
  character c1*1,c2*2
  logical is_grid4
  logical ok1,ok2
  is_grid4(grid4)=len(trim(grid4)).eq.4 .and.                        &
       grid4(1:1).ge.'A' .and. grid4(1:1).le.'R' .and.               &
       grid4(2:2).ge.'A' .and. grid4(2:2).le.'R' .and.               &
       grid4(3:3).ge.'0' .and. grid4(3:3).le.'9' .and.               &
       grid4(4:4).ge.'0' .and. grid4(4:4).le.'9'

!  print*,'b',nwords,w(1:nwords)
  if(nwords.lt.3 .or. nwords.gt.4) return
  call chkcall(w(1),bcall_1,ok1)
  call chkcall(w(2),bcall_2,ok2)
  if(w(1)(1:3).eq.'DE ' .or. w(1)(1:3).eq.'CQ_' .or. w(1)(1:4).eq.'QRZ ') ok1=.true.
  if(.not.ok1 .or. .not.ok2) return
  c1=w(nwords)(1:1)
  c2=w(nwords)(1:2)
  if(.not.is_grid4(w(nwords)(1:4)) .and. c1.ne.'+' .and. c1.ne.'-' &
       .and. c2.ne.'R+' .and. c2.ne.'R-') return
  if(c1.eq.'+' .or. c1.eq.'-') then
     ir=0
     read(w(nwords),*) irpt
  else if(c2.eq.'R+' .or. c2.eq.'R-') then
     ir=1
     read(w(nwords)(2:),*) irpt
  endif

! 1     WA9XYZ/R KA1ABC/R R FN42           28 1 28 1 1 15   74   Standard msg
! 2     PA3XYZ/P GM4ABC/P R JO22           28 1 28 1 1 15   74   EU VHF contest  

  if(nwords.eq.3 .or. (nwords.eq.4 .and. w(3)(1:2).eq.'R ')) then
     n3=0
     i3=1                          !Type 1: Standard message, possibly with "/R"
     if(index(w(1),'/P').ge.4 .or. index(w(2),'/P').ge.4) i3=2  !Type 2, with "/P"
  endif
  c13=bcall_1//'       '
  if(c13(1:3).eq.'CQ_') c13=w(1)
  call pack28(c13,n28a)
  c13=bcall_2//'       '
  call pack28(c13,n28b)
  ipa=0
  ipb=0
  if(index(w(1),'/P').ge.4 .or. index(w(1),'/R').ge.4) ipa=1
  if(index(w(2),'/P').ge.4 .or. index(w(2),'/R').ge.4) ipb=1
  
  grid4=w(nwords)(1:4)
  if(is_grid4(grid4)) then
     ir=0
     if(w(3).eq.'R ') ir=1
     j1=(ichar(grid4(1:1))-ichar('A'))*18*10*10
     j2=(ichar(grid4(2:2))-ichar('A'))*10*10
     j3=(ichar(grid4(3:3))-ichar('0'))*10
     j4=(ichar(grid4(4:4))-ichar('0'))
     igrid4=j1+j2+j3+j4
  else
     igrid4=MAXGRID4 + 35 + irpt
  endif
  write(c77,1000) n28a,ipa,n28b,ipb,ir,igrid4,i3
1000 format(2(b28.28,b1),b1,b15.15,b3.3)
!  print*,igrid4
!  print*,c77

  return
end subroutine pack77_1
