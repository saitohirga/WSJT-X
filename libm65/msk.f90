program msk

! Starting code for a JTMSK decoder.

  parameter (NSMAX=30*48000)
  character*80 infile
  character*6 cfile6
  character*12 arg
  real dat(NSMAX)
  real x(NSMAX)
  complex cx(0:NSMAX/2)
  integer hdr(11)
  integer*2 id
  common/mscom/id(NSMAX),s1(215,703),s2(215,703)

  nargs=iargc()
  if(nargs.lt.1) then
     print*,'Usage: msk <snr>'
     go to 999
  endif
  call getarg(1,arg)
  read(arg,*) snr

  open(71,file='dat.71',form='unformatted',status='old')
  read(71) id
  cfile6='123400'

  npts=30*48000
  kstep=2048
  minsigdb=6
  mousedf=0
  ntol=200 

  call random_number(x)
  nfft=NSMAX
  call four2a(x,nfft,1,-1,0)
  df=48000.0/nfft
  ia=nint(300.0/df)
  ib=nint(2800.0/df)
  cx(:ia)=0.
  cx(ib:)=0.
  call four2a(cx,nfft,1,1,-1)
  x(1)=0.
  sq=0.
  do i=1,NSMAX
     sq=sq + x(i)**2
  enddo
  rms=sqrt(sq/NSMAX)
  x=x/rms
  sig=(10.0**(0.05*snr))/32768.0
  dat=sig*id + x

  k=0
  do iblk=1,npts/kstep
     k=k+kstep
     call rtping(dat,k,cfile6,MinSigdB,MouseDF,ntol)
  enddo

999 end program msk
