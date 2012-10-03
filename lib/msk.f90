program msk

! Program to test decoding routines for mode JTMSK.

  parameter (NSMAX=30*48000)
  character*80 infile
  character*6 cfile6
  character*12 arg
  character*12 mycall
  real dat(NSMAX)
  real x(NSMAX)
  complex cx(0:NSMAX/2)
  integer hdr(11)
  integer*2 id
  common/mscom/id(NSMAX),s1(215,703),s2(215,703)

  nargs=iargc()
  if(nargs.lt.2) then
     print*,'Usage: msk nslow snr'
     go to 999
  endif
  call getarg(1,arg)
  read(arg,*) nslow
  call getarg(2,arg)
  read(arg,*) snr

! Read simulated pings from a file
  open(71,file='dat.71',form='unformatted',status='old')
  read(71) id

  cfile6='123400'
  npts=30*48000
  kstep=2048
  minsigdb=1
  mousedf=0
  ntol=200 
  mycall='W8WN'

! Make some band-limited noise.
  call random_number(x)
  nfft=NSMAX
  call four2a(x,nfft,1,-1,0)
  df=48000.0/nfft
  ia=nint(300.0/df)
  ib=nint(2700.0/df)
  cx(:ia)=0.
  cx(ib:)=0.
  call four2a(cx,nfft,1,1,-1)
  x(1)=0.
  rms=sqrt(dot_product(x,x)/NSMAX)
  x=x/rms

  sig=(10.0**(0.05*snr))/32768.0                    !Scaled signal strength
  dat=sig*id + x                                    !Add pings to noise

! This loop simulates being called from "datasink()" in program JTMSK.
  do iblk=1,npts/kstep
     k=iblk*kstep
     call rtping(dat,k,cfile6,MinSigdB,MouseDF,ntol,mycall)
     if(nslow.ne.0) call usleep(42000)
  enddo

999 end program msk
