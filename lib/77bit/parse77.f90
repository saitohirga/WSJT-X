subroutine parse77(msg,i3,n3)

  use packjt77
  character msg*37,c77*77
  call pack77(msg,i3,n3,c77)

  return
end subroutine parse77
