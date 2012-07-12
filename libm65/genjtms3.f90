subroutine genjtms3(msg28,iwave,nwave)
!subroutine genjtms3(msg28,iwave,cwave,isrch,nwave)

! Generate a JTMS3 wavefile.

  parameter (NMAX=30*48000)     !Max length of wave file
  integer*2 iwave(NMAX)         !Generated wave file
  complex cwave(NMAX)           !Alternative for searchms
  character*28 msg28            !User message
  character*29 msg
  character cc*64
  integer sentsym(203)          !Transmitted symbols (0/1)
  real sentsam(4872)            !Transmitted waveform
  real*8 dt,phi,f0,dphi,pi,twopi,samfac
  real p(0:420)
  real carrier(4872)
  real dat(4872),bb(4872),wave(4872)
  complex cdat(0:2436)
  logical first
  integer np(9)
  data np/5,7,9,11,13,17,19,23,29/  !Permissible message lengths
!                   1         2         3         4         5         6
!          0123456789012345678901234567890123456789012345678901234567890123
  data cc/'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ./?-                 _     @'/
  data samfac/1.d0/,first/.true./
  equivalence (dat,cdat)
  save

  sinc(x)=sin(pi*x)/(pi*x)

  if(first) then
     pi=4.d0*atan(1.d0)
     twopi=2.d0*pi
     x=0.
     dx=1.0/24.0
     width=3.0
     do i=1,420                                !Generate the BPSK pulse shape
        x=x+dx
        fac=0.0
        if(x/width.lt.0.5*pi) then
           fac=(cos(x/width))**2
           ipz=i
        endif
        p(i)=fac*sinc(x)
     enddo
     p(0)=1.0

     f0=10000.d0/7.d0
     dt=1.d0/48000.d0
     dphi=twopi*f0*dt
     phi=0.d0
     do i=1,4872                             !Generate the carrier
        phi=phi+dphi
        if(phi.gt.twopi)phi=phi-twopi
        xphi=phi
        carrier(i)=sin(xphi)
     enddo

     first=.false.
  endif

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
3  sentsym=0
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
        sentsym(k)=iand(1,ishft(i-1,-n))
        m=m+sentsym(k)
     enddo
     k=k+1
     sentsym(k)=iand(m,1)                   !Insert bit for even parity
  enddo
  nsym=7*msglen                             !# symbols in message
  nsam=24*nsym                              !# samples in message

  bb(1:nsam)=0.
  do j=1,nsym
     fac=1.0
     if(sentsym(j).eq.0) fac=-1.0
     k0=24*j - 23
     do i=0,ipz
        k=k0+i
        if(k.gt.nsam) k=k-nsam
        bb(k)=bb(k) + fac*p(i)
        if(i.gt.0) then
           k=k0-i
           if(k.lt.1) k=k+nsam
           bb(k)=bb(k) + fac*p(i)
        endif
     enddo
  enddo

  sq=0.
  wmax=0.
  do i=1,nsam
     wave(i)=carrier(i)*bb(i)
     sq=sq + wave(i)**2
     wmax=max(wmax,abs(wave(i)))
!     write(15,3002) i*dt,bb(i),wave(i)
!3002 format(f12.6,2f12.3)
  enddo

  rms=sqrt(sq/nsam)
!  print*,rms,wmax,wmax/rms

  fac=32767.0/wmax
  iwave(1:nsam)=fac*wave(1:nsam)

!  nwave=nsam

  nblk=30*48000/nsam
  do n=2,nblk
     i0=(n-1)*nsam
     iwave(i0+1:i0+nsam)=iwave(1:nsam)
  enddo
  nwave=i0+nsam

! Compute the spectrum
!  nfft=nsam
!  df=48000.0/nfft
!  ib=4000.0/df
!  fac=10.0/nfft
!  dat(1:nfft)=fac*bb(1:nfft)
!  call four2a(dat,nfft,1,-1,0)
!  do i=0,ib
!     sq=real(cdat(i))**2 + aimag(cdat(i))**2
!     write(14,3010) i*df,sq,10.0*log10(sq)
!3010 format(3f12.3)
!  enddo

!  if(isrch.eq.0) iwave(k+1:)=0
!  nwave=k

  return
end subroutine genjtms3
