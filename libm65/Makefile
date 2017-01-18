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

#all:	 qratest.exe tplt.exe
all:    qra64d.exe

OBJS1 = qratest.o qra64a.o sync64.o four2a.o smo.o smo121.o averms.o \
	packjt.o twkfreq.o spec64.o fmtmsg.o pctile.o \
	grid2deg.o deg2grid.o shell.o badmsg.o qra64_subs.o \
	qracodes.o npfwht.o pdmath.o qra12_63_64_irr_b.o \
	qra13_64_64_irr_e.o qra64.o \
	lorentzian.o fchisq0.o peakup.o

qra64_subs.o: ../../wsjtx/lib/qra/qra64/qra64_subs.c
	gcc -c -O2 -o qra64_subs.o ../../wsjtx/lib/qra/qra64/qra64_subs.c

qracodes.o: ../../wsjtx/lib/qra/qracodes/qracodes.c
	gcc -c -O2 -o qracodes.o ../../wsjtx/lib/qra/qracodes/qracodes.c

qra64.o: ../../wsjtx/lib/qra/qra64/qra64.c
	gcc -c -O2 -o qra64.o ../../wsjtx/lib/qra/qra64/qra64.c

npfwht.o: ../../wsjtx/lib/qra/qracodes/npfwht.c
	gcc -c -O2 -o npfwht.o ../../wsjtx/lib/qra/qracodes/npfwht.c

pdmath.o: ../../wsjtx/lib/qra/qracodes/pdmath.c
	gcc -c -O2 -o pdmath.o ../../wsjtx/lib/qra/qracodes/pdmath.c

qra12_63_64_irr_b.o: ../../wsjtx/lib/qra/qracodes/qra12_63_64_irr_b.c
	gcc -c -O2 -o qra12_63_64_irr_b.o  ../../wsjtx/lib/qra/qracodes/qra12_63_64_irr_b.c

qra13_64_64_irr_e.o: ../../wsjtx/lib/qra/qracodes/qra13_64_64_irr_e.c
	gcc -c -O2 -o qra13_64_64_irr_e.o  ../../wsjtx/lib/qra/qracodes/qra13_64_64_irr_e.c

qratest.exe: $(OBJS1)
	$(FC) -o qratest.exe $(OBJS1) C:\JTSDK\fftw3f\libfftw3f-3.dll

OBJS2 = tplt.o zplt64.o image.o
tplt.exe: $(OBJS2)
	$(FC) -o tplt.exe $(OBJS2)

OBJS3 = qra64d.o qra64c.o qra64zap.o sync64.o four2a.o smo.o averms.o \
	timer.o packjt.o twkfreq.o spec64.o fmtmsg.o pctile.o dpol.o \
	grid2deg.o deg2grid.o shell.o badmsg.o moondop.o moon2.o \
	geocentric.o toxyz.o dot.o dcoord.o \
	qra64_subs.o qracodes.o npfwht.o pdmath.o qra12_63_64_irr_b.o \
	qra13_64_64_irr_e.o qra64.o lorentzian.o fchisq0.o 

qra64d.exe: $(OBJS3)
	$(FC) -o qra64d.exe $(OBJS3) C:\JTSDK\fftw3f\libfftw3f-3.dll

.PHONY : clean

clean:
	$(RM) *.o qratest.exe tplt.exe
