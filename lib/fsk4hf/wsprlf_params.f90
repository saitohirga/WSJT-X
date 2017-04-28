!parameter (NDOWN=540)                 !Downsample factor (default 540)
parameter (NDOWN=30)                  !Downsample factor (default 540)
parameter (KK=60)                     !Information bits (50 + CRC10)
parameter (ND=300)                    !Data symbols: LDPC (300,60), r=1/5
parameter (NS=109)                    !Sync symbols (2 x 48 + Barker 13)
parameter (NR=3)                      !Ramp up/down
parameter (NN=NR+NS+ND)               !Total symbols (412)
parameter (NSPS0=8640)                !Samples per symbol at 12000 S/s
parameter (NSPS=NSPS0/NDOWN)          !Samples per MSK symbol (16)
parameter (N2=2*NSPS)                 !Samples per OQPSK symbol (32)
parameter (N13=13*N2)                 !Samples in central sync vector (416)
parameter (NZ=NSPS*NN)                !Samples in baseband waveform (6592)
parameter (NZMAX=NSPS0*NN)
parameter (NFFT1=4*NSPS,NH1=NFFT1/2)
