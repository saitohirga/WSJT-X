df /fpp /define:Win32 makedate.f90
makedate
cl /c /DWin32 /Fojtaudio.o jtaudio.c
f2py.py -c --quiet --opt="/traceback /fast /fpp /define:Win32" init_rs.o encode_rs.o decode_rs.o jtaudio.o -lwinmm -lpa -lfftw3single -llibsamplerate -m Audio --"fcompiler=compaqv" only: ftn_init ftn_quit audio_init spec getfile azdist0 astro0 makedate_sub : Audio.f90 wsjtgen.f90 runqqq.f90 wsjt1.f fsubs1.f fsubs.f astro.f astropak.f resample.c ptt.c wrapkarn.c fivehz.f90
