subroutine runqqq(fname,cmnd,iret)

#ifdef CVF
  use dflib
#endif
  integer system

  character*(*) fname,cmnd

#ifdef CVF
  iret=runqq(fname,cmnd)
#else
  iret=system('kvasd -q > dev_null')
#endif

  return
end subroutine runqqq
