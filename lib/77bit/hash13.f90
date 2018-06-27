subroutine hash13(n13,c13,isave)

  parameter (NMAX=20)
  character*13 c13,callsign(NMAX)
  integer ihash(NMAX)
  logical first
  data first/.true./
  save first,ihash,callsign

  if(first) then
     ihash=-1
     callsign='             '
     first=.false.
  endif

  if(isave.ge.0) then
     do i=1,NMAX
        if(ihash(i).eq.n13) go to 900             !This one is already in the list
     enddo
     ihash(NMAX:2:-1)=ihash(NMAX-1:1:-1)
     callsign(NMAX:2:-1)=callsign(NMAX-1:1:-1)
     ihash(1)=n13
     callsign(1)=c13
  else
     do i=1,NMAX
        if(ihash(i).eq.n13) then
           c13=callsign(i)
           go to 900
        endif
     enddo
  endif

900 return
end subroutine hash13
