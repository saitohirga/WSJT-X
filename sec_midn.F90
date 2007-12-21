real function sec_midn()

real*8 sec8,hrtime

#ifdef CVF
  sec_midn=secnds(0.0)
#else
  sec8=hrtime()
  sec_midn=mod(sec8,86400.d0)
#endif

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
