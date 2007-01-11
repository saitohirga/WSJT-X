subroutine fstatqqq(lu,istat,ierr)

#ifdef Win32
  use dfport
#endif

#ifdef Win32
  ierr=fstat(lu,istat)
#else
  call fstat(lu,istat,ierr)
#endif

  return
end subroutine fstatqqq
