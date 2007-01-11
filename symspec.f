      subroutine symspec(id,nz,ss,savg)

C  Compute spectra at four polarizations, using half-symbol steps.

      parameter (NFFT=32768)
      integer*2 id(4,nz)
      real ss(4,322,NFFT)
      real savg(4,NFFT)
      complex cx(NFFT),cy(NFFT)          !  pad to 32k with zeros
      complex z
      real*8 ts,hsym

      fac=1.e-4
      hsym=2048.d0*96000.d0/11025.d0     !Samples per half symbol
      npts=hsym                          !Integral samples per half symbol
      nsteps=322                         !Half symbols per transmission

      do ip=1,4
         do i=1,NFFT
            savg(ip,i)=0.
         enddo
      enddo

      ts=1.d0 - hsym
      do n=1,nsteps
         ts=ts+hsym             !Update exact sample pointer
         i0=ts                  !Starting sample pointer
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
            
         do i=1,NFFT            !Save and accumulate power spectra
            s=real(cx(i))**2 + aimag(cx(i))**2
            ss(1,n,i)=s         ! Pol = 0
            savg(1,i)=savg(1,i) + s

            z=cx(i) + cy(i)
            s=0.5*(real(z)**2 + aimag(z)**2)
            ss(2,n,i)=s         ! Pol = 45
            savg(2,i)=savg(2,i) + s

            s=real(cy(i))**2 + aimag(cy(i))**2
            ss(3,n,i)=s         ! Pol = 90
            savg(3,i)=savg(3,i) + s

            z=cx(i) - cy(i)
            s=0.5*(real(z)**2 + aimag(z)**2)
            ss(4,n,i)=s         ! Pol = 135
            savg(4,i)=savg(4,i) + s
         enddo
      enddo

      return
      end
