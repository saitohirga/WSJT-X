df /fpp /define:Win32 makedate.f90
makedate
cl /c /DWin32 /Fojtaudio.o jtaudio.c
f2py.py -c --quiet --opt="/traceback /fast /fpp /define:Win32" init_rs.o encode_rs.o decode_rs.o jtaudio.o -lwinmm -lpa -lfftw3single -llibsamplerate -m Audio --"fcompiler=compaqv" only: ftn_init ftn_quit audio_init spec getfile azdist0 astro0 makedate_sub : a2d.f90 abc441.f90 astro0.f90 audio_init.f90 azdist0.f90 decode1.f90 decode2.f90 decode3.f90 ftn_init.f90 ftn_quit.f90 get_fname.f90 getfile.f90 horizspec.f90 hscroll.f90 i1tor4.f90 makedate_sub.f90 rfile.f90 savedata.f90 spec.f90 wsjtgen.f90 runqqq.f90 wsjt1.f fsubs1.f fsubs.f astro.f astropak.f resample.c ptt.c wrapkarn.c fivehz.f90
