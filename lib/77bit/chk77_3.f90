subroutine chk77_3(nwords,w,i3,n3)
! Check Type 3 (One nonstandard call and one hashed call)

  character*13 w(19)
  character*13 call_1,call_2
  character*6 bcall_1,bcall_2
  character crrpt*4
  logical ok1,ok2

  if(nwords.eq.3) then
     call_1=w(1)
     if(call_1(1:1).eq.'<') call_1=w(1)(2:len(trim(w(1)))-1)
     call_2=w(2)
     if(call_2(1:1).eq.'<') call_2=w(2)(2:len(trim(w(2)))-1)
     call chkcall(call_1,bcall_1,ok1)
     call chkcall(call_2,bcall_2,ok2)
     crrpt=w(nwords)(1:4)
     i1=1
     if(crrpt(1:1).eq.'R') i1=2
     n=-99
     read(crrpt(i1:),*,err=1) n
1    if(ok1 .and. ok2 .and. n.ne.-99) then
        i3=3
        n3=0
     endif
  endif

  return
end subroutine chk77_3
