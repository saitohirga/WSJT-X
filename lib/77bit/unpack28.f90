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

  if(n28.lt.NTOKENS) then
     !code for tokens CQ, DE, QRZ, etc.
  endif
  n28=n28-NTOKENS
  if(n28.lt.N24) then
     !code for 24-bit hash
  endif
  
! Standard callsign
  n=n28 - N24
  
  i1=n/(36*10*27*27*27)
  n=n-36*10*27*27*27*i1

  i2=n/(10*27*27*27)
  n=n-10*27*27*27*i2

  i3=n/(27*27*27)
  n=n-27*27*27*i3

  i4=n/(27*27)
  n=n-27*27*i4

  i5=n/27
  i6=n-27*i5
  c13=c1(i1+1:i1+1)//c2(i2+1:i2+1)//c3(i3+1:i3+1)//c4(i4+1:i4+1)//     &
       c4(i5+1:i5+1)//c4(i6+1:i6+1)//'       '
  c13=adjustl(c13)

  return
end subroutine unpack28
