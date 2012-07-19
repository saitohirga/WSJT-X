subroutine tweak1(ca,jz,f0,cb)

! Shift frequency of analytic signal ca, with output to cb

  complex ca(jz),cb(jz)
  real*8 twopi
  complex*16 w,wstep
  data twopi/0.d0/
  save twopi

  if(twopi.eq.0.d0) twopi=8.d0*atan(1.d0)
  w=1.d0
  dphi=twopi*f0/11025.d0
  wstep=cmplx(cos(dphi),sin(dphi))
  x0=0.5*(jz+1)
  s=2.0/jz
  do i=1,jz
     x=s*(i-x0)
     w=w*wstep
     cb(i)=w*ca(i)
  enddo

  return
end subroutine tweak1
