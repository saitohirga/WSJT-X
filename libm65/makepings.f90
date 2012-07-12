subroutine makepings(iwave,nwave)

  parameter (NFSAMPLE=48000)
  integer*2 iwave(nwave)
  real*8 t

  iping0=-999
  dt=1.0/NFSAMPLE
  do i=1,nwave
     iping=i/(3*NFSAMPLE)
     if(iping.ne.iping0) then
        ip=mod(iping,3)
        w=0.015*(4-ip)
        ig=(iping-1)/3
        amp=sqrt((3.0-ig)/3.0)
        t0=dt*(iping+0.5)*(3*NFSAMPLE)
        iping0=iping
     endif
     t=(i*dt-t0)/w
     if(t.lt.0.d0 .and. t.lt.10.0) then
        fac=0.
     else
        fac=2.718*t*dexp(-t)
     endif
     iwave(i)=nint(fac*amp*iwave(i))
  enddo

  return
end subroutine makepings
