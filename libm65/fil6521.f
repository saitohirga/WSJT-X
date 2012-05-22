      subroutine fil6521(c1,n1,c2,n2)

C  FIR lowpass filter designed using ScopeFIR

C                   Pass #1   Pass #2  
C-----------------------------------------------
C  fsample    (Hz)  1378.125   Input sample rate
C  Ntaps            21         Number of filter taps
C  fc         (Hz)  40         Cutoff frequency
C  fstop      (Hz)  172.266    Lower limit of stopband
C  Ripple     (dB)  0.1        Ripple in passband
C  Stop Atten (dB)  38         Stopband attenuation
C  fout       (Hz)  344.531    Output sample rate

      parameter (NTAPS=21)
      parameter (NH=NTAPS/2)
      parameter (NDOWN=4)                !Downsample ratio = 1/4
      complex c1(n1)
      complex c2(n1/NDOWN)

C  Filter coefficients:
      real a(-NH:NH)
      data a/
     +  -0.011958606980,-0.013888627387,-0.015601306443,-0.010602249570,
     +   0.003804023436, 0.028320058273, 0.060903935217, 0.096841904411,
     +   0.129639871228, 0.152644580853, 0.160917511283, 0.152644580853,
     +   0.129639871228, 0.096841904411, 0.060903935217, 0.028320058273,
     +   0.003804023436,-0.010602249570,-0.015601306443,-0.013888627387,
     +  -0.011958606980/

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
