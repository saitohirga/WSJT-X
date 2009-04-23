subroutine sysqqq(cmnd,iret)

#ifdef CVF
  use dfport
#else
  integer system
#endif
  character*(*) cmnd

  iret=system(cmnd)

  return
end subroutine sysqqq
