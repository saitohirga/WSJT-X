program ft8d

! Decode FT8 data read from *.wav files.

! FT8 is a potential mode intended for use at 6m (and maybe HF).  It uses an
! LDPC (174,87) code, 8-FSK modulation, and 15 second T/R sequences.  Otherwise
! should behave like JT65 and JT9 as used on HF bands, except that QSOs are
! 4 x faster.

! Reception and Demodulation algorithm:
!   ... tbd ...

  include 'ft8_params.f90'
  character*12 arg
  character infile*80,datetime*13
  real s(NH1,NHSYM)
  real candidate(3,100)
  integer ihdr(11)
  integer*2 iwave(NMAX)                 !Generated full-length waveform  
  
  nargs=iargc()
  if(nargs.lt.3) then
     print*,'Usage:   ft8d MaxIt Norder file1 [file2 ...]'
     print*,'Example  ft8d   40     2   *.wav'
     go to 999
  endif
  call getarg(1,arg)
  read(arg,*) max_iterations
  call getarg(2,arg)
  read(arg,*) norder
  nfiles=nargs-2

  twopi=8.0*atan(1.0)
  fs=12000.0                             !Sample rate
  dt=1.0/fs                              !Sample interval (s)
  tt=NSPS*dt                             !Duration of "itone" symbols (s)
  ts=2*NSPS*dt                           !Duration of OQPSK symbols (s)
  baud=1.0/tt                            !Keying rate (baud)
  txt=NZ*dt                              !Transmission length (s)

  do ifile=1,nfiles
     call getarg(ifile+2,infile)
     open(10,file=infile,status='old',access='stream')
     read(10,end=999) ihdr,iwave
     close(10)
     j2=index(infile,'.wav')
     read(infile(j2-6:j2-1),*) nutc
     datetime=infile(j2-13:j2-1)
     call sync8(iwave,s,candidate,ncand)
     call ft8b(datetime,s,candidate,ncand)
  enddo   ! ifile loop

999 end program ft8d
  
