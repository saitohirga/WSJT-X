subroutine chk77_01(msg,nwords,w,nw,i3,n3)

  character*37 msg
  character*13 w(19)
  character*6 bcall_1,bcall_2
  integer nw(19)
  logical ok1,ok2
  
  call chkcall(w(1),bcall_1,ok1)
  call chkcall(w(3),bcall_2,ok2)

  if(nwords.eq.5 .and. trim(w(2)).eq.'RR73;' .and. ok1 .and. ok2) then
     i3=0                             !Type 0.1: DXpedition mode
     n3=1
  endif

  return
end subroutine chk77_01
