integer function ihashcall(c0,m)

  integer*8 n8
  character*13 c0,c1
  character*38 c
  data c/' 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ/'/

  c1=c0
  if(c1(1:1).eq.'<') c1=c1(2:)
  i=index(c1,'>')
  if(i.gt.0) c1(i:)='         '
  n8=0
  do i=1,11
     j=index(c,c1(i:i)) - 1
     n8=38*n8 + j
  enddo
  ihashcall=ishft(47055833459_8*n8,m-64)

  return
end function ihashcall
