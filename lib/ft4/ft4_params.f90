! FT4 
! LDPC(174,91) code, four 4x4 Costas arrays for Sync

parameter (KK=91)                     !Information bits (77 + CRC14)
parameter (ND=87)                     !Data symbols
parameter (NS=16)                     !Sync symbols 
parameter (NN=NS+ND)                  !Sync and data symbols (103)
parameter (NN2=NS+ND+2)               !Total channel symbols (105)
parameter (NSPS=512)                  !Samples per symbol at 12000 S/s
parameter (NZ=NSPS*NN)                !Sync and Data samples (52736)
parameter (NZ2=NSPS*NN2)              !Total samples in shaped waveform (53760)
parameter (NMAX=5*12000)              !Samples in iwave (60,000)
parameter (NFFT1=2048, NH1=NFFT1/2)   !Length of FFTs for symbol spectra
parameter (NSTEP=NSPS/4)              !Coarse time-sync step size
parameter (NHSYM=NMAX/NSTEP-3)        !Number of symbol spectra (1/4-sym steps)
parameter (NDOWN=16)                  !Downsample factor
