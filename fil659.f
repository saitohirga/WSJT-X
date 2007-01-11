      subroutine fil659(id,n1,f0,c2a,c2b,n2)

C  FIR lowpass filter designed using ScopeFIR

C  fsample    (Hz)  96000.0   Input sample rate
C  Ntaps            23        Number of filter taps
C  fc         (Hz)  1500      Cutoff frequency (-3 dB)
C  fstop      (Hz)  12000     Lower limit of stopband
C  Ripple     (dB)  0.05      Ripple in passband
C  Stop Atten (dB)  45        Stopband attenuation
C  fout       (Hz)  24000.0   Output sample rate

      parameter (NTAPS=23)
      parameter (NH=NTAPS/2)
      parameter (NDOWN=4)                !Downsample ratio = 1/4
      integer*2 id(4,n1)
      complex c2a(n1/NDOWN),c2b(n1/NDOWN)
      complex z
      real*8 dt,dpha,twopi
      complex w,w0,wstep
      data twopi/6.2831853071796/

C  Filter coefficients:
      real a(-NH:NH)
      data a/
     +  -0.006192694772,-0.009005098228,-0.011852791893,-0.011064464062,
     +  -0.004044201520, 0.010987986233, 0.034169891384, 0.063459565756,
     +   0.094796253511, 0.122845919676, 0.142302928050, 0.149270332282,
     +   0.142302928050, 0.122845919676, 0.094796253511, 0.063459565756,
     +   0.034169891384, 0.010987986233,-0.004044201520,-0.011064464062,
     +  -0.011852791893,-0.009005098228,-0.006192694772/


      n2=(n1-NTAPS+NDOWN)/NDOWN
      k0=NH-NDOWN+1

C  Loop over all output samples
      dt=1.d0/96000.d0
      dpha=twopi*f0*dt
      wstep=cmplx(cos(dpha),sin(dpha))
      k=k0+NDOWN
      w0=1.0
      do i=1,n2
         c2a(i)=0.
         c2b(i)=0.
         k=k0 + NDOWN*i
         w=w0
         do j=-NH,NH
            w=w*wstep
            if(j.eq.3-NH) w0=w
            z=a(j)*cmplx(float(id(1,j+k)),float(id(2,j+k)))*w
            c2a(i)=c2a(i) + z
            z=a(j)*cmplx(float(id(3,j+k)),float(id(4,j+k)))*w
            c2b(i)=c2b(i) + z
         enddo
      enddo

      return
      end
