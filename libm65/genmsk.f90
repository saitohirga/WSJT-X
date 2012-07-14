!subroutine genms(msg28,samfac,iwave,cwave,isrch,nwave)
subroutine genmsk(msg28,iwave,nwave)

! Generate a JTMS wavefile.

  parameter (NMAX=30*48000)     !Max length of wave file
  integer*2 iwave(NMAX)         !Generated wave file
  complex cwave(NMAX)           !Alternative for searchms
  character*28 msg28            !User message
  character*29 msg
  character cc*64
  integer sent(203)
  real*8 dt,phi,f,f0,dfgen,dphi,twopi,foffset,samfac
  integer np(9)
  data np/5,7,9,11,13,17,19,23,29/  !Permissible message lengths
!                   1         2         3         4         5         6
!          0123456789012345678901234567890123456789012345678901234567890123
  data cc/'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ./?-                 _     @'/

!###
  samfac=1.d0
  isrch=0
!###

  msg=msg28//' '                               !Extend to 29 characters
  do i=28,1,-1                                 !Find user's message length
     if(msg(i:i).ne.' ') go to 1
  enddo
1 iz=i+1                                       !Add one for space at EOM
  msglen=iz
  if(isrch.ne.0) go to 3
  do i=1,9
     if(np(i).ge.iz) go to 2
  enddo
  i=8
2 msglen=np(i)

! Convert message to a bit sequence, 7 bits per character (6 + even parity)
3  sent=0
  k=0
  do j=1,msglen
     if(msg(j:j).eq.' ') then
        i=58
        go to 5
     else
        do i=1,64
           if(msg(j:j).eq.cc(i:i)) go to 5
        enddo
     endif
5    m=0
     do n=5,0,-1                            !Each character gets 6 bits
        k=k+1
        sent(k)=iand(1,ishft(i-1,-n))
        m=m+sent(k)
     enddo
     k=k+1
     sent(k)=iand(m,1)                      !Insert parity bit
  enddo
  nsym=k

 ! Set up necessary constants
  twopi=8.d0*atan(1.d0)
  nsps=24
  dt=1.d0/(samfac*48000.d0)
  f0=48000.d0/nsps
  dfgen=0.5d0*f0
  foffset=1500.d0 - f0
  print*,f0,dfgen,foffset
  t=0.d0
  k=0
  phi=0.d0
  nrpt=NMAX/(nsym*nsps)
  if(isrch.ne.0) nrpt=1

  do irpt=1,nrpt
     do j=1,nsym
        if(sent(j).eq.1) then
           f=f0 + 0.5d0*dfgen + foffset
        else
           f=f0 - 0.5d0*dfgen + foffset
        endif
        dphi=twopi*f*dt
        do i=1,nsps
           k=k+1
           phi=phi+dphi
           if(isrch.eq.0) then
              iwave(k)=nint(32767.0*sin(phi))
           else
              cwave(k)=cmplx(cos(phi),sin(phi))
           endif
        enddo
     enddo
  enddo

  if(isrch.eq.0) iwave(k+1:)=0
  nwave=k

  return
end subroutine genmsk
