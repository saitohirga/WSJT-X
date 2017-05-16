! LDPC (300,60) code
parameter (NDOWN=24)                  !Downsample factor
parameter (KK=60)                     !Information bits (50 + CRC10)
parameter (ND=100)                    !Data symbols
parameter (NS=14)                     !Sync symbols (2 @ Costas 7x7)
parameter (NN=NS+ND)                  !Total symbols (114)
parameter (NSPS0=24576)               !Samples per symbol at 12000 S/s
parameter (NSPS=NSPS0/NDOWN)          !Sam/sym, downsampled (1024)
parameter (N7=7*NSPS)                 !Samples in Costas 7x7 array (7168)
parameter (NZ=NSPS*NN)                !Samples in downsampled waveform (116,736)
parameter (NZMAX=NSPS0*NN)            !Samples in *.wav (2,801,664)
parameter (NFFT1=4*NSPS,NH1=NFFT1/2)
parameter (NH2=NSPS/2)
