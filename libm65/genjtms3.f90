subroutine genjtms3(msg,msgsent,iwave,nwave)

  character*22 msg,msgsent
  integer*1 chansym(258)
  integer*2 iwave(30*48000)
  integer dgen(13)
  integer*1 data0(13)                   
  integer*1 datsym(215)
  real*8 pi,twopi,f0,dt,phi,dphi
  real*4 p(-3095:3096)
  real*4 s(6192)
  real*4 carrier(6192)
  logical first
  integer indx0(9)                               !Indices of duplicated symbols
  data indx0 /16,38,60,82,104,126,148,170,192/
  data first/.true./
  save
  sinc(x)=sin(pi*x)/(pi*x)

  if(first) then
     pi=4.d0*atan(1.d0)
     twopi=2.d0*pi
     k=0
     x=0.
     dx=1.0/24.0
     do i=1,3096                             !Generate the BPSK pulse shape
        k=k+1
        if(k.gt.3096) k=k-6192
        x=x+dx
        p(k)=sinc(x) * (sinc(x/2.0))**2
!        p(k)=sinc(x) * exp(-(x/2.0)**2)
        if(k.ne.3096) p(-k)=p(k)
     enddo
     p(0)=1.0

     f0=193.d0*48000.d0/(258.d0*24.d0)
     dt=1.d0/48000.d0
     dphi=twopi*f0*dt
     phi=0.d0
     nmax=0.
     do i=1,6192                             !Generate the carrier
        phi=phi+dphi
        if(phi.gt.twopi)phi=phi-twopi
        xphi=phi
        carrier(i)=sin(xphi)
     enddo
  endif

  call packmsg(msg,dgen)                  !Pack message into 12 six-bit symbols
  call entail(dgen,data0)           !Move from 6-bit to 8-bit symbols, add tail
  ndat=(72+31)*2
  call encode232(data0,ndat,datsym)       !Convolutional encoding

  do i=1,9                              !Duplicate 9 symbols at end of datsym
     datsym(206+i)=datsym(indx0(i))
  enddo

  call scr258(isync,datsym,1,chansym)   !Insert sync and data into chansym(258)

  if(msg(1:1).eq.'@') chansym=0

  s=0.
  do j=1,258
     k1=-3096-24*j
     if(chansym(j).eq.1) s=s + cshift(p,k1)
     if(chansym(j).eq.0) s=s - cshift(p,k1)
  enddo

  nmax=0
  do i=1,6192
     n=30000.0*carrier(i)*s(i)
     nmax=max(nmax,abs(n))
     if(n.gt.32767) n=32767
     if(n.lt.-32767) n=-32767
     iwave(i)=n
  enddo

!  print*,'nmax:',nmax
  nwave=6192
  msgsent=msg

  return
end subroutine genjtms3
