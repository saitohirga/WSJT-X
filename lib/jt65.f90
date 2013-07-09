program jt65

! Test the JT65 decoder for WSJT-X

  parameter (NZMAX=60*12000)
  integer*4 ihdr(11)
  integer*2 id2(NZMAX)
  real*4 dd(NZMAX)
  character*80 infile
  integer*2 nfmt2,nchan2,nbitsam2,nbytesam2
  character*4 ariff,awave,afmt,adata
  common/hdr/ariff,lenfile,awave,afmt,lenfmt,nfmt2,nchan2, &
     nsamrate,nbytesec,nbytesam2,nbitsam2,adata,ndata
  common/tracer/limtrace,lu
  equivalence (lenfile,ihdr(2))

  nargs=iargc()
  if(nargs.lt.1) then
     print*,'Usage: jt65 file1 [file2 ...]'
     go to 999
  endif
  limtrace=0
  lu=12

  newdat=1
  ntol=50
  nfa=2700
!  nfb=4000
  nfqso=933
  nagain=0

  open(12,file='timer.out',status='unknown')
  open(22,file='kvasd.dat',access='direct',recl=1024,status='unknown')

  call timer('jt65    ',0)

  do ifile=1,nargs
     call getarg(ifile,infile)
     open(10,file=infile,access='stream',status='old',err=998)

     call timer('read    ',0)
     read(10) ihdr
     nutc=ihdr(1)                           !Silence compiler warning
     i1=index(infile,'.wav')
     read(infile(i1-4:i1-1),*,err=10) nutc
     go to 20
10    nutc=0
20    npts=52*12000
     read(10) id2(1:npts)
     call timer('read    ',1)
     dd(1:npts)=id2(1:npts)
     dd(npts+1:)=0.

     call timer('jt65a   ',0)
     call jt65a(dd,npts,newdat,nutc,ntol,nfa,nfqso,nagain,ndecoded)
     call timer('jt65a   ',1)
  enddo

  call timer('jt65    ',1)
  call timer('jt65    ',101)
  call four2a(a,-1,1,1,1)                  !Free the memory used for plans
  call filbig(a,-1,1,0.0,0,0,0,0,0)        ! (ditto)
  go to 999

998 print*,'Cannot open file:'
  print*,infile

999 end program jt65
