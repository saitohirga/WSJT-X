subroutine genfsk4(id,f0,c)

  parameter (NR=4)                      !Ramp up, ramp down
  parameter (NS=12)                     !Sync symbols (2 @ Costas 4x4)
  parameter (ND=84)                     !Data symbols: LDPC (168,84), r=1/2
  parameter (NN=NR+NS+ND)               !Total symbols (100)
  parameter (NSPS=2688)                 !Samples per symbol at 12000 sps
  parameter (NZ=NSPS*NN)                !Samples in waveform (268800)
  parameter (NFFT=512*1024)
  parameter (NSYNC=NS*NSPS)
  parameter (NDOWN=168)
  parameter (NFFT2=NZ/NDOWN,NH2=NFFT2/2) !3200
  parameter (NSPSD=NFFT2/NN)

  complex c(0:NFFT-1)                   !Complex waveform
  complex cf(0:NFFT-1)
  real*8 twopi,dt,fs,baud,f0,dphi,phi
  integer id(NN)                        !Encoded 2-bit data (values 0-3)
  integer icos4(4)                      !4x4 Costas array
  data icos4/0,1,3,2/

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
     dphi=twopi*(f0 + id(j)*baud)*dt
     do i=1,NSPS
        k=k+1
        phi=phi+dphi
        if(phi.gt.twopi) phi=phi-twopi
        xphi=phi
        c(k)=cmplx(cos(xphi),sin(xphi))
     enddo
  enddo

  nh=NFFT/2
  df=12000.0/NFFT
  cf=c
  call four2a(cf,NFFT,1,-1,1)           !Transform to frequency domain

  if(sum(id).ne.0) then
     flo=f0-baud
     fhi=f0+4*baud
     do i=0,NFFT-1                         !Remove spectral sidelobes
        f=i*df
        if(i.gt.nh) f=(i-nfft)*df
        if(f.le.flo .or. f.ge.fhi) cf(i)=0.
     enddo
  endif

  c=cf
  call four2a(c,NFFT,1,1,1)            !Transform back to time domain
  c=c/nfft
  
  return
end subroutine genfsk4
