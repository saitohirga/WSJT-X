parameter (KK=64)                     !Information bits (50 + CRC14) ?
parameter (ND=200)                    !Data symbols: LDPC (204,68), r=1/3, don't send last 4 bits
parameter (NS=16)                     !Sync symbols (16)
parameter (NN=NS+ND)                  !Total symbols (216)

parameter (NSPS0=6400)                !Samples per symbol at 12000 S/s

parameter (NDOWN=32)                  !Downsample to 200 sa/symbol (375 Hz) for candidate selection
parameter (NSPS=NSPS0/NDOWN)          !Samples per symbol
parameter (NZ=NSPS*NN)                !Samples in baseband waveform 

parameter (NZ0=NSPS0*NN)              !Samples in waveform at 12000 S/s
parameter (NFFT1=4*NSPS,NH1=NFFT1/2)

