      subroutine ps(dat,nfft,s)

      parameter (NMAX=16384+2)
      parameter (NHMAX=NMAX/2-1)
      real dat(nfft)
      real s(NHMAX)
      real x(NMAX)
      complex c(0:NHMAX)
      equivalence (x,c)

      nh=nfft/2
      do i=1,nfft
         x(i)=dat(i)/128.0       !### Why 128 ??
      enddo

      call xfft(x,nfft)
      fac=1.0/nfft
      do i=1,nh
         s(i)=fac*(real(c(i))**2 + aimag(c(i))**2)
      enddo

      return
      end
