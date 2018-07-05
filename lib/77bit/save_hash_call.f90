subroutine save_hash_call(c13,n10,n12,n22)

  parameter (MAXHASH=20)
  character*13 c13,callsign(MAXHASH)
  integer ihash10(MAXHASH),ihash12(MAXHASH),ihash22(MAXHASH)
  logical first
  common/hashcom/ihash10,ihash12,ihash22,callsign
  save first,/hashcom/

  
  if(first) then
     ihash10=-1
     ihash12=-1
     ihash22=-1
     callsign='             '
     first=.false.
  endif

  n10=ihashcall(c13,10)
  n12=ihashcall(c13,12)
  n22=ihashcall(c13,22)
  do i=1,MAXHASH
     if(ihash22(i).eq.n22) go to 900     !This one is already in the table
  enddo

! New entry: move table down, making room for new one at the top
  ihash10(MAXHASH:2:-1)=ihash10(MAXHASH-1:1:-1)
  ihash12(MAXHASH:2:-1)=ihash12(MAXHASH-1:1:-1)
  ihash22(MAXHASH:2:-1)=ihash22(MAXHASH-1:1:-1)

! Add the new entry
  callsign(MAXHASH:2:-1)=callsign(MAXHASH-1:1:-1)
  ihash10(1)=n10
  ihash12(1)=n12
  ihash22(1)=n22
  callsign(1)=c13

900 return
end subroutine save_hash_call
