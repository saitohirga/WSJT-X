subroutine sysqqq(cmnd,iret)

#ifdef Win32
  use dfport
#else
  integer system
#endif
  character*(*) cmnd

!  iret=system(cmnd)

  return
end subroutine sysqqq
