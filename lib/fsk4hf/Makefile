# Compilers
CC = gcc
CXX = g++
FC = gfortran

FFLAGS = -O2 -fbounds-check -Wall -Wno-conversion
CFLAGS = -O2 -I. 

# Default rules
%.o: %.c
	${CC} ${CFLAGS} -c $<
%.o: %.f
	${FC} ${FFLAGS} -c $<
%.o: %.F
	${FC} ${FFLAGS} -c $<
%.o: %.f90
	${FC} ${FFLAGS} -c $<
%.o: %.F90
	${FC} ${FFLAGS} -c $<

all:	fsk4sim

OBJS0 = testpsk.o four2a.o bpfilter.o nonlinear.o tweak1.o spectrum.o smo.o
testpsk: $(OBJS0)
	$(FC) -o testpsk $(OBJS0) -lfftw3f

OBJS1 = gmsk8.o four2a.o gaussfilt.o
gmsk8: $(OBJS1)
	$(FC) -o gmsk8 $(OBJS1) -lfftw3f

OBJS2 = testfsk.o four2a.o smo.o
testfsk: $(OBJS2)
	$(FC) -o testfsk $(OBJS2) -lfftw3f

OBJS3 = fsk2sim.o four2a.o smo.o wavhdr.o gran.o 
fsk2sim: $(OBJS3)
	$(FC) -o fsk2sim $(OBJS3) -lfftw3f

OBJS4 = fsk4sim.o four2a.o wavhdr.o gran.o tweak1.o
fsk4sim: $(OBJS4)
	$(FC) -o fsk4sim $(OBJS4) -lfftw3f

.PHONY : clean

clean:
	$(RM) *.o testpsk testfsk fsk2sim fsk4sim
