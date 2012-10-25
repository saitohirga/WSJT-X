subroutine grid2n(grid,n)
  character*4 grid

  i1=ichar(grid(1:1))-ichar('A')
  i2=ichar(grid(3:3))-ichar('0')
  i=10*i1 + i2
  n=-i - 31

  return
end subroutine grid2n
