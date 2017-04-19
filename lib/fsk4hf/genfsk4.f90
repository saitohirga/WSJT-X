subroutine genfsk4(id,f00,nts,c)

  parameter (ND=60)                      !Data symbols: LDPC (120,60), r=1/2
  parameter (NN=ND)                      !Total symbols (60)
  parameter (NSPS=57600)                 !Samples per symbol at 12000 sps
  parameter (NZ=NSPS*NN)                 !Samples in waveform (3456000)
  parameter (NFFT=NZ)                    !Full length FFT

  complex c(0:NFFT-1)                    !Complex waveform
  real*8 twopi,dt,fs,baud,f0,dphi,phi
  integer id(NN)                         !Encoded 2-bit data (values 0-3)

  f0=f00
  twopi=8.d0*atan(1.d0)
  fs=12000.d0
  dt=1.0/fs
  baud=1.d0/(NSPS*dt)

! Generate the 4-FSK waveform
  x=0.
  c=0.
  phi=0.d0
  k=-1
  do j=1,NN
     dphi=twopi*(f0 + nts*id(j)*baud)*dt
     do i=1,NSPS
        k=k+1
        phi=phi+dphi
        if(phi.gt.twopi) phi=phi-twopi
        xphi=phi
        c(k)=cmplx(cos(xphi),sin(xphi))
     enddo
  enddo

  return
end subroutine genfsk4
