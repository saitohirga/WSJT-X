subroutine rfile(lu,ibuf,n,ierr)

  integer*1 ibuf(n)

  call cs_lock('rfile')
  read(lu,end=998) ibuf
  ierr=0
  go to 999
998 ierr=1002
999 continue
  call cs_unlock
  return
end subroutine rfile
