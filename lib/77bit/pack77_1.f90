subroutine pack77_1(nwords,w,i3,n3,c77)
! Check Type 1 (Standard 77-bit message) and Type 3 (ditto, with a "/P" call)

  character*13 w(19),c13
  character*77 c77
  character*6 bcall_1,bcall_2
  character*4 grid4
  logical is_grid4
  logical ok1,ok2
  is_grid4(grid4)=len(trim(grid4)).eq.4 .and.                        &
       grid4(1:1).ge.'A' .and. grid4(1:1).le.'R' .and.               &
       grid4(2:2).ge.'A' .and. grid4(2:2).le.'R' .and.               &
       grid4(3:3).ge.'0' .and. grid4(3:3).le.'9' .and.               &
       grid4(4:4).ge.'0' .and. grid4(4:4).le.'9'

  if(nwords.lt.3 .or. nwords.gt.4) return
  call chkcall(w(1),bcall_1,ok1)
  call chkcall(w(2),bcall_2,ok2)
  if(.not.ok1 .or. .not.ok2) return
  if(.not.is_grid4(w(nwords)(1:4))) return

! 1     WA9XYZ/R KA1ABC/R R FN42           28 1 28 1 1 15   74   Standard msg
! 3     PA3XYZ/P GM4ABC/P R JO22           28 1 28 1 1 15   74   EU VHF contest  

  if(nwords.eq.3 .or. (nwords.eq.4 .and. w(3)(1:2).eq.'R ')) then
     n3=0
     i3=1                          !Type 1: Standard message
     if(index(w(1),'/P').ge.4 .or. index(w(2),'/P').ge.4) i3=3
  endif
  c13=bcall_1//'       '
  call pack28(c13,n28a)
  c13=bcall_2//'       '
  call pack28(c13,n28b)
  ipa=0
  ipb=0
  if(index(w(1),'/P').ge.4 .or. index(w(1),'/R').ge.4) ipa=1
  if(index(w(2),'/P').ge.4 .or. index(w(2),'/R').ge.4) ipb=1
  ir=0
  if(w(3).eq.'R ') ir=1
  grid4=w(nwords)(1:4)
  j1=(ichar(grid4(1:1))-ichar('A'))*18*10*10
  j2=(ichar(grid4(2:2))-ichar('A'))*10*10
  j3=(ichar(grid4(3:3))-ichar('0'))*10
  j4=(ichar(grid4(4:4))-ichar('0'))
  igrid4=j1+j2+j3+j4
  write(c77,1000) n28a,ipa,n28b,ipb,ir,igrid4,i3
1000 format(2(b28.28,b1),b1,b15.15,b3.3)

  return
end subroutine pack77_1
