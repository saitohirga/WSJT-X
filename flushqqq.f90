subroutine flushqqq(lu)

#ifdef Win32
  use dfport
#endif

  call flush(lu)

  return
end subroutine flushqqq
