subroutine fmtmsg77(msg)

  character*37 msg

! Convert all letters to upper case
  iz=len(trim(msg))
  do i=1,iz
     if(msg(i:i).ge.'a' .and. msg(i:i).le.'z')                       &
          msg(i:i)= char(ichar(msg(i:i))+ichar('A')-ichar('a'))
  enddo

  do iter=1,10                           !Collapse multiple blanks into one
     ib2=index(msg(1:iz),'  ')
     if(ib2.lt.1) go to 900
     msg=msg(1:ib2)//msg(ib2+2:)
     iz=iz-1
  enddo

900 return
end subroutine fmtmsg77
