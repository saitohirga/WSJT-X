logical function badmsg(msg)
  character*22 msg
  character*42 c
  data c/'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ +-./?'/

  do i=1,22
     do j=1,42
        if(msg(i:i).eq.c(j:j)) go to 10
     enddo
     badmsg=.true.
     return
10   continue
  enddo
  badmsg=.false.

  return
end function badmsg

