!----------------------------------------------------- getfile
subroutine getfile(fname,len)
  character*(*) fname

  include 'datcom.f90'
  include 'gcom2.f90'

  fname80=fname
  nlen=len
  newdat2=1
  ierr=0

  return
end subroutine getfile
