      subroutine symspec(id,kbuf,kk,kkdone,rxnoise,newspec)

C  Compute spectra at four polarizations, using half-symbol steps.

      parameter (NFFT=32768)
      parameter (NSMAX=60*96000)
      integer*2 id(4,NSMAX)
      complex cx(NFFT),cy(NFFT)          !  pad to 32k with zeros
      complex z
      real*8 ts,hsym
      common/spcom/ip0,ss(4,322,NFFT),ss5(322,NFFT),savg(4,NFFT)

      fac=1.e-4
!       fac=1.7e-4
!       fac=0.0002 * 10.0**(0.05*(-rxnoise))
      hsym=2048.d0*96000.d0/11025.d0 !Samples per half symbol
      npts=hsym                 !Integral samples per half symbol
      ntot=322                  !Half symbols per transmission

      if(kkdone.eq.0) then
         do ip=1,4
            do i=1,NFFT
               savg(ip,i)=0.
            enddo
         enddo
         ts=1.d0 - hsym
         n=0
      endif

      do nn=1,ntot
         i0=ts+hsym             !Starting sample pointer
         if((i0+npts-1).gt.kk) go to 999  !See if we have enough points
         ts=ts+hsym             !OK, update the exact sample pointer
         do i=1,npts            !Copy data to FFT arrays
            xr=fac*id(1,i0+i)
            xi=fac*id(2,i0+i)
            cx(i)=cmplx(xr,xi)
            yr=fac*id(3,i0+i)
            yi=fac*id(4,i0+i)
            cy(i)=cmplx(yr,yi)
         enddo

         do i=npts+1,NFFT       !Pad to 32k with zeros
            cx(i)=0.
            cy(i)=0.
         enddo

         call four2a(cx,NFFT,1,1,1) !Do the FFTs
         call four2a(cy,NFFT,1,1,1)
            
         n=n+1
         do i=1,NFFT            !Save and accumulate power spectra
            sx=real(cx(i))**2 + aimag(cx(i))**2
            ss(1,n,i)=sx         ! Pol = 0
            savg(1,i)=savg(1,i) + sx

            z=cx(i) + cy(i)
            s45=0.5*(real(z)**2 + aimag(z)**2)
            ss(2,n,i)=s45         ! Pol = 45
            savg(2,i)=savg(2,i) + s45

            sy=real(cy(i))**2 + aimag(cy(i))**2
            ss(3,n,i)=sy         ! Pol = 90
            savg(3,i)=savg(3,i) + sy

            z=cx(i) - cy(i)
            s135=0.5*(real(z)**2 + aimag(z)**2)
            ss(4,n,i)=s135         ! Pol = 135
            savg(4,i)=savg(4,i) + s135

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
            ss5(n,i)=0.707*sqrt(q*q + u*u)

         enddo
         if(n.eq.ntot) then
            newspec=1
            go to 999
         endif
      enddo

 999  return
      end
