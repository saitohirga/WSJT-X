!------------------------------------------------ ftn_quit
subroutine ftn_quit
  include 'gcom1.f90'
  ngo=0
  call four2a(a,-1,1,1,1)
!  @@@ Should also terminate the plans created in filbig!
  return
end subroutine ftn_quit
