subroutine runqqq(fname,cmnd,iret)

#ifdef CVF
  use dflib
#endif
  integer system

  character*(*) fname,cmnd

#ifdef CVF
  iret=runqq(fname,cmnd)
#else
!  iret=system('./KVASD -q >& /dev/null')
  iret=system('KVASD -q')
! print*,iret
#endif

  return
end subroutine runqqq
