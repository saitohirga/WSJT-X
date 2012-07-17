program msk

! Starting code for a JTMSK decoder.

  parameter (NSMAX=30*48000)
  character*80 infile
  character*6 cfile6
  real dat(NSMAX)
  integer hdr(11)
  integer*2 id
  common/mscom/id(NSMAX),s1(215,703),s2(215,703)

  nargs=iargc()
  if(nargs.lt.1) then
     print*,'Usage: msk file1 [file2 ...]'
     print*,'       Reads data from *.wav files.'
     go to 999
  endif

  npts=30*48000
  kstep=2048
  minsigdb=6
  mousedf=0
  ntol=200 

  do ifile=1,nargs
     call getarg(ifile,infile)
     open(10,file=infile,access='stream',status='old',err=998)
     read(10) hdr
     read(10) id
     close(10)
     hdr(1)=hdr(2)
     i1=index(infile,'.wav')
     cfile6=infile(i1-6:i1-1)
     dat=id

     k=0
     do iblk=1,npts/kstep
        k=k+kstep
        call rtping(dat,k,cfile6,MinSigdB,MouseDF,ntol)
     enddo
  enddo

  go to 999

998 print*,'Cannot open file:'
  print*,infile

999 end program msk
