program ms3

! Starting code for a JTMS3 decoder.

  character*80 infile
  integer hdr(11)
  integer*2 id
  common/mscom/id(1440000),s1(215,703),s2(215,703)

  nargs=iargc()
  if(nargs.lt.1) then
     print*,'Usage: ms3 file1 [file2 ...]'
     print*,'       Reads data from *.wav files.'
     go to 999
  endif

  npts=30*48000
  kstep=4096

  do ifile=1,nargs
     call getarg(ifile,infile)
     open(10,file=infile,access='stream',status='old',err=998)
     read(10) hdr
     read(10) id
     close(10)

     do k=kstep,npts,kstep
        call specjtms(k)
     enddo
  enddo

  go to 999

998 print*,'Cannot open file:'
  print*,infile

999 end program ms3
