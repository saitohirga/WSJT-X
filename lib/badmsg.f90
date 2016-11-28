subroutine badmsg(irc,dat,nc1,nc2,ng2)

! Get rid of a few QRA64 false decodes that cannot be correct messages.  

  integer dat(12)                           !Decoded message (as 12 integers)

  ic1=ishft(dat(1),22) + ishft(dat(2),16) + ishft(dat(3),10)+         &
       ishft(dat(4),4) + iand(ishft(dat(5),-2),15)

! Test for "......" or "CQ 000"
  if(ic1.eq.262177560 .or. ic1.eq.262177563) then
     irc=-1
     return
  endif

  ic2=ishft(iand(dat(5),3),26) + ishft(dat(6),20) +                   &
       ishft(dat(7),14) + ishft(dat(8),8) + ishft(dat(9),2) +         &
       iand(ishft(dat(10),-4),3)

  ig=ishft(iand(dat(10),15),12) + ishft(dat(11),6) + dat(12)

  if(ic1.eq.nc1 .and. ic2.eq.nc2 .and. ng.ne.32401 .and. ig.ne.ng) irc=-1

  return
end subroutine badmsg
