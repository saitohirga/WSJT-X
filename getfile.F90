!----------------------------------------------------- getfile
subroutine getfile(fname,len)
  character*(*) fname
  character*80 fname80
  parameter (NSMAX=60*96000)          !Samples per 60 s file
  integer*2 id(4,NSMAX)               !46 MB: raw data from Linrad timf2
  common/datcom/nutc,newdat2,id,fname80,nlen
  include 'gcom2.f90'

  fname80=fname
  nlen=len
  newdat2=1
  ierr=0

  return
end subroutine getfile
