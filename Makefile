gcc = CC
FC = g77
FFLAGS = -O -Wall -fbounds-check

OBJS1 = JT65code.o nchar.o grid2deg.o packmsg.o packtext.o \
	packcall.o packgrid.o unpackmsg.o unpacktext.o unpackcall.o \
	unpackgrid.o deg2grid.o packdxcc.o chkmsg.o getpfx1.o \
	getpfx2.o k2grid.o grid2k.o interleave63.o graycode.o set.o \
	igray.o init_rs_int.o encode_rs_int.o decode_rs_int.o \
	wrapkarn.o

all:	JT65code

JT65code: $(OBJS1)
	$(FC) -o JT65code $(OBJS1)

init_rs_int.o: init_rs.c
	$(CC) -c -DBIGSYM=1 -o init_rs_int.o init_rs.c

encode_rs_int.o: encode_rs.c
	$(CC) -c -DBIGSYM=1 -o encode_rs_int.o encode_rs.c

decode_rs_int.o: decode_rs.c
	$(CC) -c -DBIGSYM=1 -o decode_rs_int.o decode_rs.c

.PHONY : clean
clean:
	-rm *.o JT65code

