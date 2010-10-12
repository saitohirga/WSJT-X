gcc -c plrr_subs_win.c
g95 -o pulsar -fno-second-underscore -fbounds-check -ftrace=full pulsar.f90 plrr_subs_win.o
