! LDPC (174,87) code
parameter (KK=87)                     !Information bits (75 + CRC12)
parameter (ND=58)                     !Data symbols
parameter (NS=21)                     !Sync symbols (3 @ Costas 7x7)
parameter (NN=NS+ND)                  !Total symbols (79)
parameter (NSPS=2048)                 !Samples per symbol at 12000 S/s
parameter (N7=7*NSPS)                 !Samples in Costas 7x7 array (14,336)
parameter (NZ=NSPS*NN)                !Samples in full 15 s waveform (161,792)
parameter (NMAX=15*12000)             !Samples in iwave (180,000)
parameter (NFFT1=2*NSPS, NH1=NFFT1/2) !Length of FFTs for symbol spectra
parameter (NHSYM=2*NMAX/NSPS-1)       !Number of symbol spectra (half-symbol steps)
