subroutine flushqqq(lu)

#ifdef CVF
  use dfport
#endif

  call flush(lu)

  return
end subroutine flushqqq
