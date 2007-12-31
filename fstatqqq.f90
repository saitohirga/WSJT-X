subroutine fstatqqq(lu,istat,ierr)

#ifdef CVF
  use dfport
#endif

#ifdef CVF
  ierr=fstat(lu,istat)
#else
  call fstat(lu,istat,ierr)
#endif

  return
end subroutine fstatqqq
