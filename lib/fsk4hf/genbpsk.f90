subroutine genbpsk(id,f00,ndiff,nref,c)

  parameter (ND=121)                     !Data symbols: LDPC (120,60), r=1/2
  parameter (NN=ND)                      !Total symbols (121)
  parameter (NSPS=28800)                 !Samples per symbol at 12000 sps
  parameter (NZ=NSPS*NN)                 !Samples in waveform (3456000)

  complex c(0:NZ-1)                      !Complex waveform
  real*8 twopi,dt,fs,baud,f0,dphi,phi
  integer id(NN)                         !Encoded NRZ data (values +/-1)
  integer ie(NN)                         !Differentially encoded data

  f0=f00
  twopi=8.d0*atan(1.d0)
  fs=12000.d0
  dt=1.0/fs
  baud=1.d0/(NSPS*dt)

  if(ndiff.ne.0) then
     ie(1)=1                             !First bit is always 1
     do i=2,NN                           !Differentially encode
        ie(i)=id(i)*ie(i-1)
     enddo
  endif

! Generate the BPSK waveform
  phi=0.d0
  k=-1
  do j=1,NN
     dphi=twopi*f0*dt
     x=id(j)
     if(ndiff.ne.0) x=ie(j)                !Differential
     if(nref.ne.0) x=1.0                   !Generate reference carrier
     do i=1,NSPS
        k=k+1
        phi=phi+dphi
        if(phi.gt.twopi) phi=phi-twopi
        xphi=phi
        c(k)=x*cmplx(cos(xphi),sin(xphi))
     enddo
  enddo

  return
end subroutine genbpsk
