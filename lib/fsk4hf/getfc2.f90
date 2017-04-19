subroutine getfc2(c,fc1,fc2)

  parameter (KK=84)                     !Information bits (72 + CRC12)
  parameter (ND=168)                    !Data symbols: LDPC (168,84), r=1/2
  parameter (NS=65)                     !Sync symbols (2 x 26 + Barker 13)
  parameter (NR=3)                      !Ramp up/down
  parameter (NN=NR+NS+ND)               !Total symbols (236)
  parameter (NSPS=16)                   !Samples per MSK symbol (16)
  parameter (N2=2*NSPS)                 !Samples per OQPSK symbol (32)
  parameter (N13=13*N2)                 !Samples in central sync vector (416)
  parameter (NZ=NSPS*NN)                !Samples in baseband waveform (3760)
  parameter (NFFT1=4*NSPS,NH1=NFFT1/2)

  complex c(0:NZ-1)                     !Complex waveform
  complex cs(0:NZ-1)                    !For computing spectrum
  real a(5)

  fs=12000.0/72.0
  baud=fs/NSPS
  a(1)=-fc1
  a(2:5)=0.
  call twkfreq1(c,NZ,fs,a,cs)         !Mix down by fc1

! Filter, square, then FFT to get refined carrier frequency fc2.
  call four2a(cs,NZ,1,-1,1)          !To freq domain
  df=fs/NZ
  ia=nint(0.75*baud/df) 
  cs(ia:NZ-1-ia)=0.                  !Save only freqs around fc1
  call four2a(cs,NZ,1,1,1)           !Back to time domain
  cs=cs/NZ
  cs=cs*cs                           !Square the data
  call four2a(cs,NZ,1,-1,1)          !Compute squared spectrum

! Find two peaks separated by baud
  pmax=0.
  fc2=0.
  ic=nint(baud/df)
  ja=nint(0.5*baud/df)
  do j=-ja,ja
     f2=j*df
     ia=nint((f2-0.5*baud)/df)
     if(ia.lt.0) ia=ia+NZ
     ib=nint((f2+0.5*baud)/df)
     p=real(cs(ia))**2 + aimag(cs(ia))**2 +                        &
          real(cs(ib))**2 + aimag(cs(ib))**2           
     if(p.gt.pmax) then
        pmax=p
        fc2=0.5*f2
     endif
!           write(52,1200) f2,p,db(p)
!1200       format(f10.3,2f15.3)
  enddo

  return
end subroutine getfc2
