subroutine pack77_02(nwords,w,i3,n3,c77)

  character*13 w(19),c13
  character*77 c77
  character*6 bcall_1,grid6
  logical ok1,is_grid6

  is_grid6(grid6)=len(trim(grid6)).eq.6 .and.                        &
       grid6(1:1).ge.'A' .and. grid6(1:1).le.'R' .and.               &
       grid6(2:2).ge.'A' .and. grid6(2:2).le.'R' .and.               &
       grid6(3:3).ge.'0' .and. grid6(3:3).le.'9' .and.               &
       grid6(4:4).ge.'0' .and. grid6(4:4).le.'9' .and.               &
       grid6(5:5).ge.'A' .and. grid6(5:5).le.'X' .and.               &
       grid6(6:6).ge.'A' .and. grid6(6:6).le.'X'

  call chkcall(w(1),bcall_1,ok1)
  if(.not.ok1) return                            !bcall_1 must be a valid basecall
  if(nwords.lt.3 .or. nwords.gt.4) return        !nwords must be 3 or 4
  nx=-1
  if(nwords.ge.2) read(w(nwords-1),*,err=2) nx
2 if(nx.lt.520001 .or. nx.gt.594095) return      !Exchange between 520001 - 594095
  if(.not.is_grid6(w(nwords)(1:6))) return       !Last word must be a valid grid6

! Type 0.2:   PA3XYZ/P R 590003 IO91NP           28 1 1 3 12 25   70   EU VHF contest
  i3=0
  n3=2
  ip=0
  c13=w(1)
  i=index(w(1),'/P')
  if(i.ge.4) then
     ip=1
     c13=w(1)(1:i-1)//'         '
  endif
  call pack28(c13,n28a)
  ir=0
  if(w(2)(1:2).eq.'R ') ir=1
  irpt=nx/10000 - 52
  iserial=mod(nx,10000)
  grid6=w(nwords)(1:6)
  j1=(ichar(grid6(1:1))-ichar('A'))*18*10*10*24*24
  j2=(ichar(grid6(2:2))-ichar('A'))*10*10*24*24
  j3=(ichar(grid6(3:3))-ichar('0'))*10*24*24
  j4=(ichar(grid6(4:4))-ichar('0'))*24*24
  j5=(ichar(grid6(5:5))-ichar('A'))*24
  j6=(ichar(grid6(6:6))-ichar('A'))
  igrid6=j1+j2+j3+j4+j5+j6
  write(c77,1010) n28a,ip,ir,irpt,iserial,igrid6,n3,i3
1010 format(b28.28,2b1,b3.3,b12.12,b25.25,b4.4,b3.3)

  return
end subroutine pack77_02
