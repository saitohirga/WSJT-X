gcc -c wrapkarn.c
gcc -c igray.c
f77 -o JT65code -fno-second-underscore JT65code_all.f igray.o wrapkarn.o init_rs.o encode_rs.o decode_rs.o
