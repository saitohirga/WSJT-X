subroutine unpacktext(nc1,nc2,nc3,msg)

  character*22 msg
  character*44 c
  data c/'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ +-./?'/

  nc3=iand(nc3,32767)                      !Remove the "plain text" bit
  if(iand(nc1,1).ne.0) nc3=nc3+32768
  nc1=nc1/2
  if(iand(nc2,1).ne.0) nc3=nc3+65536
  nc2=nc2/2

  do i=5,1,-1
     j=mod(nc1,42)+1
     msg(i:i)=c(j:j)
     nc1=nc1/42
  enddo

  do i=10,6,-1
     j=mod(nc2,42)+1
     msg(i:i)=c(j:j)
     nc2=nc2/42
  enddo

  do i=13,11,-1
     j=mod(nc3,42)+1
     msg(i:i)=c(j:j)
     nc3=nc3/42
  enddo
  msg(14:22) = '         '

  return
end subroutine unpacktext


