gcc -c wrapkarn.c
g95 -o JT65code -fno-second-underscore JT65code_all.f wrapkarn.o init_rs.o encode_rs.o decode_rs.o
