subroutine unpacktext77(c71,c13)

  real*16 q,q1
  integer*8 n1,n2
  character*13 c13
  character*71 c71
  character*42 c
  data c/' 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ+-./?'/

  read(c71,1001) n1,n2
1001 format(b63,b8)
  q=n1*256.q0 + n2

  do i=13,1,-1
     q1=mod(q,42.q0)
     j=q1+1.q0
     c13(i:i)=c(j:j)
     q=(q-q1)/42.q0
  enddo

  return
end subroutine unpacktext77
