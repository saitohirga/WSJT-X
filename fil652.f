      subroutine fil652(c1,n1,c2,n2)

C  FIR lowpass filter designed using ScopeFIR

C  fsample     = 2756.25  Hz
C  Ntaps       = 31
C  fc          = 500      Hz
C  fstop       = 689.0625 Hz
C  Ripple      = 0.5      dB
C  Stop Atten  = 50       dB
C  fout        = 1378.125 Hz

      parameter (NTAPS=31)
      parameter (NH=NTAPS/2)
      parameter (NDOWN=2)                !Downsample ratio
      complex c1(n1)
      complex c2(*)

C  Filter coefficients:
      real a(-NH:NH)
      data a/
     +  -0.000859869246,-0.008518289484,-0.011250152625,-0.001061705256,
     +   0.013958392156, 0.010047338728,-0.015003870003,-0.025027880982,
     +   0.007151700557, 0.043634723913, 0.016788108012,-0.061886192062,
     +  -0.073548459520, 0.075261027466, 0.306638863577, 0.419826269508,
     +   0.306638863577, 0.075261027466,-0.073548459520,-0.061886192062,
     +   0.016788108012, 0.043634723913, 0.007151700557,-0.025027880982,
     +  -0.015003870003, 0.010047338728, 0.013958392156,-0.001061705256,
     +  -0.011250152625,-0.008518289484,-0.000859869246/

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
