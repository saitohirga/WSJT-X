parameter (KK=64)                     !Information bits (50 + CRC14) ?
parameter (ND=200)                    !Data symbols: LDPC (204,68), r=1/3, don't send last 4 bits
parameter (NS=32)                     !Sync symbols (32)
parameter (NN=NS+ND)                  !Total symbols (232)

parameter (NSPS0=6000)                !Samples per symbol at 12000 S/s

parameter (NDOWN=30)                  !Downsample to 200 sa/symbol (400 Hz) for candidate selection
parameter (NSPS=NSPS0/NDOWN)          !Samples per symbol (200)
parameter (NZ=NSPS*NN)                !Samples in baseband waveform 

parameter (NZ0=NSPS0*NN)              !Samples in waveform at 12000 S/s
parameter (NFFT1=4*NSPS,NH1=NFFT1/2)

