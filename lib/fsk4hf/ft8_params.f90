! LDPC (168,84) code
parameter (KK=84)                     !Information bits (72 + CRC12)
parameter (ND=56)                     !Data symbols
parameter (NS=21)                     !Sync symbols (3 @ Costas 7x7)
parameter (NN=NS+ND)                  !Total symbols (77)
parameter (NSPS=2048)                 !Samples per symbol at 12000 S/s
parameter (N7=7*NSPS)                 !Samples in Costas 7x7 array (14,336)
parameter (NZ=NSPS*NN)                !Samples in full 15 s waveform (157,696)
parameter (NMAX=15*12000)             !Samples in iwave (180,000)
parameter (NFFT1=1*NSPS, NH1=NFFT1/2) !Length of FFTs for symbol spectra
