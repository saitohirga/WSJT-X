
!----------------------------------------------------- rfile
subroutine rfile(lu,ibuf,n,ierr)

  integer*1 ibuf(n)

  read(lu,end=998) ibuf
  ierr=0
  go to 999
998 ierr=1002
999  return
end subroutine rfile
