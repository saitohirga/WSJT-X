#CC = gcc
CC = clang
FC = gfortran

FFLAGS = -O2 -Wall -Wno-conversion
CFLAGS= -I/usr/include -Wall -Wno-missing-braces -O2
LDFLAGS = -L/usr/lib
LIBS = -lfftw3 -lm

# Default rules
%.o: %.c $(DEPS)
	${CC} ${CFLAGS} -c $<
%.o: %.f
	${FC} ${FFLAGS} -c $<
%.o: %.F
	${FC} ${FFLAGS} -c $<
%.o: %.f90
	${FC} ${FFLAGS} -c $<
%.o: %.F90
	${FC} ${FFLAGS} -c $<

all:    wsprd WSPRcode test_wspr

DEPS = fano.h
OBJS1 = wsprd.o wsprd_utils.o fano.o tab.o nhash.o
wsprd: $(OBJS1)
	$(CC) -o $@ $^ $(CFLAGS) $(LDFLAGS) $(LIBS)

OBJS2 = test_wspr.o unpk.o wsprd_utils.o nhash.o
test_wspr: $(OBJS2) libwspr.a
	$(FC) -o test_wspr $(FFLAGS) $(OBJS2) libwspr.a


OBJS3 = WSPRcode.o
WSPRcode: $(OBJS3) libwspr.a
	$(FC) -o WSPRcode $(FFLAGS) $(OBJS3) libwspr.a

clean:
	rm *.o wsprd 
