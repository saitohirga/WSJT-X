subroutine unpack28(n28,c13)

  parameter (NTOKENS=4874084,N24=16777216)
  integer nc(6)
  character*13 c13
  character*37 c1
  character*36 c2
  character*10 c3
  character*27 c4
  data c1/' 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'/
  data c2/'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'/
  data c3/'0123456789'/
  data c4/' ABCDEFGHIJKLMNOPQRSTUVWXYZ'/
  data nc/37,36,19,27,27,27/

  n=n28 - NTOKENS - N24
  j=mod(n,nc(6))
  c13(6:6)=c4(j+1:j+1)
  n=n/nc(6)

  j=mod(n,nc(5))
  c13(5:5)=c4(j+1:j+1)
  n=n/nc(5)

  j=mod(n,nc(4))
  c13(4:4)=c4(j+1:j+1)
  n=n/nc(4)

  j=mod(n,nc(3))
  c13(3:3)=c3(j+1:j+1)
  n=n/nc(3)

  j=mod(n,nc(2))
  c13(2:2)=c2(j+1:j+1)
  n=n/nc(2)

  j=n
  c13(1:1)=c1(j+1:j+1)
  c13(7:)='       '

  return
end subroutine unpack28
