subroutine genfsk4hf(msgbits,f0,id,c)

  parameter (KK=84)                     !Information bits (72 + CRC12)
  parameter (ND=84)                     !Data symbols: LDPC (168,84), r=1/2
  parameter (NS=12)                     !Sync symbols (3 @ 4x4 Costas arrays)
  parameter (NR=2)                      !Ramp up/down
  parameter (NN=NR+NS+ND)               !Total symbols (98)
  parameter (NSPS=2688/84)              !Samples per symbol (32)
  parameter (NZ=NSPS*NN)                !Samples in baseband waveform (3136)

  complex c(0:NZ-1)                     !Complex waveform
  integer id0(NN)                       !2-bit data (values 0-3), all symbols
  integer id(ND)                        !2-bit data (values 0-3), data only
  integer*1 msgbits(KK),codeword(2*ND)
  integer icos4(4)                      !4x4 Costas array
  data icos4/0,1,3,2/

  twopi=8.0*atan(1.0)
  fs=12000.0/84.0
  dt=1.0/fs
  baud=1.0/(NSPS*dt)
  call encode168(msgbits,codeword)      !Encode the test message
  id0(1)=0                               !Ramp-up
  id0(2:5)=icos4                         !First Costas array
  id0(48:51)=icos4                       !Second
  id0(94:97)=icos4                       !Third
  id0(98)=0                              !Ramp down
  j=5
  do i=1,84                             !Data symbols
     id(i)=2*codeword(2*i-1) + codeword(2*i)
     j=j+1
     if(i.eq.43) j=j+4
     id0(j)=id(i)
  enddo

! Generate the 4-FSK waveform, low tone at f=0
  c=0.
  phi=0.d0
  k=-1
  do j=1,NN
     dphi=twopi*(f0+id0(j)*baud)*dt
     do i=1,NSPS
        k=k+1
        phi=phi+dphi
        if(phi.gt.twopi) phi=phi-twopi
        c(k)=cmplx(cos(phi),sin(phi))
     enddo
  enddo

  return
end subroutine genfsk4hf
