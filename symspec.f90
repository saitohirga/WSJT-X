subroutine symspec(id,kbuf,kk,kkdone,nutc,newdat)

!  Compute spectra at four polarizations, using half-symbol steps.

  parameter (NSMAX=60*96000)
  integer*2 id(4,NSMAX,2)
  complex z
  real*8 ts,hsym
  include 'spcom.f90'
  include 'gcom2.f90'
  complex cx(NFFT),cy(NFFT)               !  pad to 32k with zeros
  data kbuf0/-999/,n/0/
  save

  kkk=kk
  if(kbuf.eq.2) kkk=kk-5760000
  fac=0.0002
  hsym=2048.d0*96000.d0/11025.d0          !Samples per half symbol
  npts=hsym                               !Integral samples per half symbol
  ntot=322                                !Half symbols per transmission
!  ntot=279                               !Half symbols in 51.8 sec

  if(kbuf.ne.kbuf0 .or. ndiskdat.eq.1) then
     kkdone=0
     kbuf0=kbuf
     ts=1.d0 - hsym
     n=0
     do ip=1,4
        do i=1,NFFT
           szavg(ip,i)=0.
        enddo
     enddo

! Get baseline power level for this minute
     n1=200                               !Block size (somewhat arbitrary)
     n2=(kkk-kkdone)/n1                   !Number of blocks
     k=0                                  !Starting place
     sqq=0.
     nsqq=0
     do j=1,n2
        sq=0.
        do i=1,n1                         !Find power in each block
           k=k+1
           x1=id(1,k,kbuf)
           x2=id(2,k,kbuf)
           x3=id(3,k,kbuf)
           x4=id(4,k,kbuf)
           sq=sq + x1*x1 + x2*x2 + x3*x3 + x4*x4
        enddo
        if(sq.lt.n1*10000.) then          !Find power in good blocks
           sqq=sqq+sq
           nsqq=nsqq+1
        endif
     enddo
     sqave=sqq/nsqq                       !Average power in good blocks
     nclip=0
     nz2=0
  endif

  if(nblank.ne.0) then
! Apply final noise blanking
     n2=(kkk-kkdone)/n1
     k=kkdone
     do j=1,n2
        sq=0.
        do i=1,n1
           k=k+1
           x1=id(1,k,kbuf)
           x2=id(2,k,kbuf)
           x3=id(3,k,kbuf)
           x4=id(4,k,kbuf)
           sq=sq + x1*x1 + x2*x2 + x3*x3 + x4*x4
        enddo
! If power in this block is excessive, blank it.
        if(sq.gt.1.5*sqave) then
           do i=k-n1+1,k
              id(1,i,kbuf)=0
              id(2,i,kbuf)=0
              id(3,i,kbuf)=0
              id(4,i,kbuf)=0
           enddo
           nclip=nclip+1
        endif
     enddo
     nz2=nz2+n2
     pctblank=nclip*100.0/nz2
  endif

  do nn=1,ntot
     i0=ts+hsym                           !Starting sample pointer
     if((i0+npts-1).gt.kkk) go to 998     !See if we have enough points
     i1=ts+2*hsym                         !Next starting sample pointer
     ts=ts+hsym                           !OK, update the exact sample pointer
     do i=1,npts                          !Copy data to FFT arrays
        xr=fac*id(1,i0+i,kbuf)
        xi=fac*id(2,i0+i,kbuf)
        cx(i)=cmplx(xr,xi)
        yr=fac*id(3,i0+i,kbuf)
        yi=fac*id(4,i0+i,kbuf)
        cy(i)=cmplx(yr,yi)
     enddo

     do i=npts+1,NFFT                   !Pad to 32k with zeros
        cx(i)=0.
        cy(i)=0.
     enddo

     call four2a(cx,NFFT,1,1,1)         !Do the FFTs
     call four2a(cy,NFFT,1,1,1)
            
     n=n+1
     do i=1,NFFT                        !Save and accumulate power spectra
        sx=real(cx(i))**2 + aimag(cx(i))**2
        ssz(1,n,i)=sx                    ! Pol = 0
        szavg(1,i)=szavg(1,i) + sx
        
        z=cx(i) + cy(i)
        s45=0.5*(real(z)**2 + aimag(z)**2)
        ssz(2,n,i)=s45                   ! Pol = 45
        szavg(2,i)=szavg(2,i) + s45

        sy=real(cy(i))**2 + aimag(cy(i))**2
        ssz(3,n,i)=sy                    ! Pol = 90
        szavg(3,i)=szavg(3,i) + sy

        z=cx(i) - cy(i)
        s135=0.5*(real(z)**2 + aimag(z)**2)
        ssz(4,n,i)=s135                  ! Pol = 135
        szavg(4,i)=szavg(4,i) + s135

        z=cx(i)*conjg(cy(i))

! Leif's formula:
!            ss5(n,i)=0.5*(sx+sy) + (real(z)**2 + aimag(z)**2 -
!     +          sx*sy)/(sx+sy)

! Leif's suggestion:
!            ss5(n,i)=max(sx,s45,sy,s135)

! Linearly polarized component, from the Stokes parameters:
        q=sx - sy
        u=2.0*real(z)
!            v=2.0*aimag(z)
        ssz5(n,i)=0.707*sqrt(q*q + u*u)

     enddo
!         if(n.eq.ntot) then
     if(n.ge.279) then
        call move(ssz5,ss5,322*NFFT)
        call cs_lock('symspec')
        write(utcdata,1002) nutc
1002    format(i4.4)
        call cs_unlock
        utcdata=utcdata(1:2)//':'//utcdata(3:4)
        newspec=1
        call move(ssz,ss,4*322*NFFT)
        call move(szavg,savg,4*NFFT)
        newdat=1
        ndecoding=1
        go to 999
     endif
     kkdone=i1-1
     nhsym=n
     call sleep_msec(0)
  enddo

998 kkdone=i1-1
999 continue

  return
end subroutine symspec
