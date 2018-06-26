subroutine split77(msg,nwords,nw,w)

! Convert msg to upper case; collapse multiple blanks; parse into words.

  character*37 msg
  character*13 w(19)
  character*1 c,c0
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
     w(k)(n:n)=c                                !Copy character c into word
     c0=c
  enddo
  iz=j                                          !Message length
  nwords=k                                      !Number of words in msg
  nw(k)=len(trim(w(k)))
  msg(iz+1:)='                                     '

  return
end subroutine split77
