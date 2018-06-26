subroutine chk77_02(nwords,w,i3,n3)

  character*13 w(19)
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
  if(nwords.eq.3 .or. nwords.eq.4) then
     n=-1
     if(nwords.ge.2) read(w(nwords-1),*,err=2) n
2    if(ok1 .and. n.ge.520001 .and. n.le.594095 .and. is_grid6(w(nwords)(1:6))) then
        i3=0
        n3=2                          !Type 0.2: EU VHF+ Contest
     endif
  endif

  return
end subroutine chk77_02
