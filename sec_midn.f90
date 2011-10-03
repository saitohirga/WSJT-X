real function sec_midn()
  sec_midn=secnds(0.0)
  return
end function sec_midn

subroutine sleep_msec(n)

#ifdef CVF
  use dflib
#endif

#ifdef CVF
  call sleepqq(n)
#else
  call usleep(1000*n)
#endif

  return
end subroutine sleep_msec
