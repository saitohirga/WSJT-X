subroutine setupmsk(cw,cwb)

! Calculate the JTMS character waveforms.

  complex cw(168,0:63)
  complex cwb(168)
  integer nb(7)
!  real*8 twopi,dt,f0,f1
  character cc*64
!                   1         2         3         4         5         6
!          0123456789012345678901234567890123456789012345678901234567890123
  data cc/'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ./?-                 _     @'/

  nsps=24
  twopi=8.d0*atan(1.d0)
  dt=1.d0/48000.d0                     !Sample interval
  f0=1000.d0
  f1=2000.d0
  dphi0=twopi*dt*f0
  dphi1=twopi*dt*f1

  do i=0,63
     k=0
     m=0
     do n=5,0,-1                          !Each character gets 6+1 bits
        k=k+1
        nb(k)=iand(1,ishft(i,-n))
        m=m+nb(k)
     enddo
     k=k+1
     nb(k)=iand(m,1)                      !Insert parity bit

     phi=0.
     j=0
     do k=1,7                             !Generate the waveform
        if(nb(k).eq.0) then
           dphi=dphi0
        else
           dphi=dphi1
        endif
        do ii=1,nsps
           j=j+1
           phi=phi+dphi
           cw(j,i)=cmplx(cos(phi),sin(phi))
        enddo
     enddo
  enddo
  cwb=cw(1:168,57)

  return
end subroutine setupmsk
