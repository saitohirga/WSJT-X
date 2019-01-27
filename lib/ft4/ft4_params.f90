! FT4 
! LDPC (174,91) code

parameter (KK=91)                     !Information bits (77 + CRC14)
parameter (ND=87)                     !Data symbols
parameter (NS=16)                     !Sync symbols 
parameter (NN=NS+ND)                  !Total channel symbols (103)
parameter (NSPS=512)                  !Samples per symbol at 12000 S/s
parameter (NZ=NSPS*NN)                !Samples in full 4.395 s message frame (52736)
parameter (NMAX=5.0*12000)            !Samples in iwave (60,000)
parameter (NFFT1=2048, NH1=NFFT1/2)   !Length of FFTs for symbol spectra
parameter (NSTEP=NSPS/4)              !Coarse time-sync step size
parameter (NHSYM=NMAX/NSTEP-3)        !Number of symbol spectra (1/4-sym steps)
parameter (NDOWN=16)                  !Downsample factor
