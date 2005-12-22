      subroutine xfft(x,nfft)

C  Real-to-complex FFT.

      real x(nfft)

!      call four2(x,nfft,1,-1,0)
      call four2a(x,nfft,1,-1,0)

      return
      end

