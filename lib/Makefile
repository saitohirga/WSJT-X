# Set paths
EXE_DIR = ..\\..\\wsjtx_install
QT_DIR = C:/wsjt-env/Qt5/5.2.1/mingw48_32
FFTW3_DIR = ..

INCPATH = -I${QT_DIR}/include/QtCore -I${QT_DIR}/include 

# Compilers
CC = gcc
CXX = g++
FC = gfortran
AR = ar cr
RANLIB = ranlib
MKDIR = mkdir -p
CP = cp
RM = rm -f

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

all:	 qratest.exe

OBJS1 = qratest.o qra64a.o sync64.o four2a.o smo.o smo121.o averms.o \
	timer_module.o packjt.o twkfreq.o spec64.o fmtmsg.o pctile.o \
	grid2deg.o deg2grid.o shell.o badmsg.o qra64_subs.o \
	qracodes.o npfwht.o pdmath.o qra12_63_64_irr_b.o \
	qra13_64_64_irr_e.o qra64.o

qra64_subs.o: qra/qra64/qra64_subs.c
	gcc -c -O2 -o qra64_subs.o qra/qra64/qra64_subs.c

qracodes.o: qra/qracodes/qracodes.c
	gcc -c -O2 -o qracodes.o qra/qracodes/qracodes.c

qra64.o: qra/qra64/qra64.c
	gcc -c -O2 -o qra64.o qra/qra64/qra64.c

npfwht.o: qra/qracodes/npfwht.c
	gcc -c -O2 -o npfwht.o qra/qracodes/npfwht.c

pdmath.o: qra/qracodes/pdmath.c
	gcc -c -O2 -o pdmath.o qra/qracodes/pdmath.c

qra12_63_64_irr_b.o: qra/qracodes/qra12_63_64_irr_b.c
	gcc -c -O2 -o qra12_63_64_irr_b.o  qra/qracodes/qra12_63_64_irr_b.c

qra13_64_64_irr_e.o: qra/qracodes/qra13_64_64_irr_e.c
	gcc -c -O2 -o qra13_64_64_irr_e.o  qra/qracodes/qra13_64_64_irr_e.c


qratest.exe: $(OBJS1)
	$(FC) -o qratest.exe $(OBJS1) C:\JTSDK\fftw3f\libfftw3f-3.dll

.PHONY : clean

clean:
	$(RM) *.o qratest.exe 
