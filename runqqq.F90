subroutine runqqq(fname,cmnd,iret)

#ifdef Win32
  use dflib
#endif
  integer system

  character*(*) fname,cmnd

#ifdef Win32
  iret=runqq(fname,cmnd)
#else
  iret=system('./KVASD -q >& /dev/null')
#endif

  return
end subroutine runqqq
