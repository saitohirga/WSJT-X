subroutine hash10(n10,c13)

  parameter (MAXHASH=20)
  character*13 c13,callsign(MAXHASH)
  integer ihash10(MAXHASH),ihash12(MAXHASH),ihash22(MAXHASH)
  common/hashcom/ihash10,ihash12,ihash22,callsign
  save /hashcom/
  
  c13='<...>'
  do i=1,MAXHASH
     if(ihash10(i).eq.n10) then
        c13=callsign(i)
        go to 900
     endif
  enddo

900 return
end subroutine hash10
