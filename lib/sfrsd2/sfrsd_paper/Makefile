CC = gcc
FC = gfortran

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

all:    probs.out

OBJS1 = prob.o binomial_subs.o
prob:   $(OBJS1)
	$(FC) -o prob $(OBJS1)

probs.out: prob
#             x  N  X  s
	prob 35 63 40 40 > probs.out
	prob 37 63 40 45 >> probs.out
	prob 37 53 40 45 >> probs.out
	prob 38 53 40 47 >> probs.out

clean:
	rm -rf *.o prob probs.out

