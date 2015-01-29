gcc -c gran.c
gfortran -c fftw3mod.f90
gfortran -o timefft timefft.f90 timefft_opts.f90 gran.o libfftw3f-3.dll
