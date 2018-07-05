subroutine split77(msg,nwords,nw,w)

! Convert msg to upper case; collapse multiple blanks; parse into words.

  character*37 msg
  character*13 w(19)
  character*1 c,c0
  character*6 bcall_1
  logical ok1
  integer nw(19)
    
  iz=len(trim(msg))
  j=0
  k=0
  n=0
  c0=' '
  w='             '
  do i=1,iz
     c=msg(i:i)                                 !Single character
     if(c.eq.' ' .and. c0.eq.' ') cycle         !Skip leading/repeated blanks
     if(c.ne.' ' .and. c0.eq.' ') then
        k=k+1                                   !New word
        n=0
     endif
     j=j+1                                      !Index in msg
     n=n+1                                      !Index in word
     msg(j:j)=c
     if(c.ge.'a' .and. c.le.'z') msg(j:j)=char(ichar(c)-32)  !Force upper case
     if(n.le.13) w(k)(n:n)=c                    !Copy character c into word
     c0=c
  enddo
  iz=j                                          !Message length
  nwords=k                                      !Number of words in msg
  nw(k)=len(trim(w(k)))
  msg(iz+1:)='                                     '
  
  call chkcall(w(3),bcall_1,ok1)
  if(ok1 .and. w(1)(1:3).eq.'CQ ') then
     w(1)='CQ_'//w(2)(1:10)
     w(2:12)=w(3:13)
     nwords=nwords-1
  endif
  
  return
end subroutine split77
