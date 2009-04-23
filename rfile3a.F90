!----------------------------------------------------- rfile3a
subroutine rfile3a(infile,ibuf,n,ierr)

  character*(*) infile
  integer*1 ibuf(n)

#ifdef CVF
  open(10,file=infile,form='binary',status='old',err=998)
#else
  open(10,file=infile,access='stream',status='old',err=998)
#endif
  read(10,end=998) ibuf
  ierr=0
  go to 999
998 ierr=1002
999 close(10)
  return
end subroutine rfile3a
