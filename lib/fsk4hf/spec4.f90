subroutine spec4(c,s,savg)

  parameter (KK=84)                     !Information bits (72 + CRC12)
  parameter (ND=84)                     !Data symbols: LDPC (168,84), r=1/2
  parameter (NS=12)                     !Sync symbols (3 @ 4x4 Costas arrays)
  parameter (NR=2)                      !Ramp up/down
  parameter (NN=NR+NS+ND)               !Total symbols (98)
  parameter (NSPS=2688/84)              !Samples per symbol (32)
  parameter (NZ=NSPS*NN)                !Samples in baseband waveform (3760)
  parameter (NFFT=2*NSPS,NH=NSPS)

  complex c(0:NZ-1)
  complex c1(0:NFFT-1)
  real s(0:NH,NN)
  real savg(0:NH)

  fs=12000.0/84.0
  df=fs/NFFT
  savg=0.
  do j=1,NN
     ia=(j-1)*NSPS
     ib=ia + NSPS-1
     c1(0:NSPS-1)=c(ia:ib)
     c1(NSPS:)=0.
     call four2a(c1,NFFT,1,-1,1)
     do k=1,NSPS
        s(k,j)=real(c1(k))**2 + aimag(c1(k))**2
     enddo
     savg=savg+s(0:NH,j)
  enddo
  s=s/NZ
  savg=savg/(NN*NZ)

  return
end subroutine spec4
