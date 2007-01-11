      subroutine fil658(c1,n1,c2,n2)

C  FIR lowpass filter designed using ScopeFIR

C                   Pass #1   Pass #2   Pass #3
C-----------------------------------------------
C  fsample    (Hz)  96000.0   24000     6000         Input sample rate
C  Ntaps            47        47        47           Number of filter taps
C  fc         (Hz)  6000      1500      375          Cutoff frequency (-3 dB)
C  fstop      (Hz)  11025.0   2756.25   689.0625     Lower limit of stopband
C  Ripple     (dB)  0.06      0.06      0.06         Ripple in passband
C  Stop Atten (dB)  41        41        41           Stopband attenuation
C  fout       (Hz)  24000.0   6000      1500         Output sample rate

      parameter (NTAPS=47)
      parameter (NH=NTAPS/2)
      parameter (NDOWN=4)                !Downsample ratio = 1/4
      complex c1(n1)
      complex c2(n1/NDOWN)

C  Filter coefficients:
      real a(-NH:NH)
      data a/
     +   0.004066057444,-0.000483030239,-0.002085155775,-0.004036668720,
     +  -0.005338083014,-0.004952374329,-0.002267639582, 0.002499787691,
     +   0.008113543743, 0.012522509052, 0.013441779030, 0.009233544068,
     +  -0.000256999594,-0.013156485907,-0.025660797518,-0.032755808092,
     +  -0.029602578877,-0.013013352845, 0.017249853203, 0.057885304099,
     +   0.102497204557, 0.142897857652, 0.171067807479, 0.181167084990,
     +   0.171067807479, 0.142897857652, 0.102497204557, 0.057885304099,
     +   0.017249853203,-0.013013352845,-0.029602578877,-0.032755808092,
     +  -0.025660797518,-0.013156485907,-0.000256999594, 0.009233544068,
     +   0.013441779030, 0.012522509052, 0.008113543743, 0.002499787691,
     +  -0.002267639582,-0.004952374329,-0.005338083014,-0.004036668720,
     +  -0.002085155775,-0.000483030239, 0.004066057444/

      n2=(n1-NTAPS+NDOWN)/NDOWN
      k0=NH-NDOWN+1

C  Loop over all output samples
      do i=1,n2
         c2(i)=0.
         k=k0 + NDOWN*i
         do j=-NH,NH
            c2(i)=c2(i) + c1(j+k)*a(j)
         enddo
      enddo

      return
      end
