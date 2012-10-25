subroutine n2grid(n,grid)
  character*4 grid
  character*1 c1,c2

  if(n.gt.-31 .or. n.lt.-70) stop 'Error in n2grid'
  i=-(n+31)                           !NB: 0 <= i <= 39
  i1=i/10
  i2=mod(i,10)
  grid(1:1)=char(ichar('A')+i1)
  grid(2:2)='A'
  grid(3:3)=char(ichar('0')+i2)
  grid(4:4)='0'

  return
end subroutine n2grid
