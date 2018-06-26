subroutine chk77_1(nwords,w,i3,n3)
! Check Type 1 (Standard 77-bit message) and Type 4 (ditto, with a "/P" call)

  character*13 w(19)
  character*6 bcall_1,bcall_2
  character*4 grid4
  logical is_grid4
  logical ok1,ok2

  is_grid4(grid4)=len(trim(grid4)).eq.4 .and.                        &
       grid4(1:1).ge.'A' .and. grid4(1:1).le.'R' .and.               &
       grid4(2:2).ge.'A' .and. grid4(2:2).le.'R' .and.               &
       grid4(3:3).ge.'0' .and. grid4(3:3).le.'9' .and.               &
       grid4(4:4).ge.'0' .and. grid4(4:4).le.'9'

  call chkcall(w(1),bcall_1,ok1)
  call chkcall(w(2),bcall_2,ok2)
  
  if(nwords.eq.3 .or. nwords.eq.4) then
     if(ok1 .and. ok2 .and. is_grid4(w(nwords)(1:4))) then
        if(nwords.eq.3 .or. (nwords.eq.4 .and. w(3)(1:2).eq.'R ')) then
           i3=1                          !Type 1: Standard message
           if(index(w(1),'/P').ge.4 .or. index(w(2),'/P').ge.4) i3=4
           n3=0
        endif
     endif
  endif

  return
end subroutine chk77_1
