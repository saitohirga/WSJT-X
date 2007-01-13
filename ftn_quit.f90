!------------------------------------------------ ftn_quit
subroutine ftn_quit
  include 'gcom1.f90'
  ngo=0
! Destroy the FFTW plans
  call four2a(a,-1,1,1,1)
  call filbig(id,-1,f0,newdat,c4a,c4b,n4)
  return
end subroutine ftn_quit
