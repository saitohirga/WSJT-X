program jt65

! Test the JT65 decoder for WSJT-X

  use options
  character c
  logical :: display_help=.false.
  parameter (NZMAX=60*12000)
  integer*4 ihdr(11)
  integer*2 id2(NZMAX)
  real*4 dd(NZMAX)
  character*80 infile
  character(len=500) optarg
  common/tracer/limtrace,lu
  equivalence (lenfile,ihdr(2))
  type (option) :: long_options(5) = [ &
    option ('freq',.true.,'f','signal frequency, default FREQ=1270','FREQ'),         &
    option ('help',.false.,'h','Display this help message',''),                      &
    option ('ntrials',.true.,'n','number of trials, default TRIALS=10000','TRIALS'), &
    option ('robust-sync',.false.,'r','robust sync',''),                             &
    option ('single-signal-mode',.false.,'s','decode at signal frequency only','') ]

limtrace=0
lu=12
ntol=10
nfqso=1270
nagain=0
nsubmode=0
ntrials=10000
nlow=200
nhigh=4000
n2pass=2
nrobust=0

  do
    call getopt('f:hn:rs',long_options,c,optarg,narglen,nstat,noffset,nremain,.true.)
    if( nstat .ne. 0 ) then
      exit
    end if
    select case (c)
      case ('f')
        read (optarg(:narglen), *) nfqso
      case ('h')
        display_help = .true.
      case ('n')
        read (optarg(:narglen), *) ntrials
      case ('r')
        nrobust=1
      case ('s')
        nlow=nfqso-ntol
        nhigh=nfqso+ntol
        n2pass=1
    end select
  end do

  if(display_help .or. nstat.lt.0 .or. nremain.lt.1) then
     print *, ''
     print *, 'Usage: jt65 [OPTIONS] file1 [file2 ...]'
     print *, ''
     print *, '       JT65 decode pre-recorded .WAV file(s)'
     print *, ''
     print *, 'OPTIONS:'
     print *, ''
     do i = 1, size (long_options)
       call long_options(i) % print (6)
     end do
     go to 999
  endif

  open(12,file='timer.out',status='unknown')
  call timer('jt65    ',0)

  ndecoded=0
  do ifile=noffset+1,noffset+nremain
     newdat=1
     nfa=nlow
     nfb=nhigh
     call get_command_argument(ifile,optarg,narglen)
     infile=optarg(:narglen)
     open(10,file=infile,access='stream',status='old',err=998)
     call timer('read    ',0)
     read(10) ihdr
     i1=index(infile,'.wav')
     if( i1 .eq. 0 ) i1=index(infile,'.WAV')
     read(infile(i1-4:i1-1),*,err=998) nutc
     npts=52*12000
     read(10) id2(1:npts)
     call timer('read    ',1)
     dd(1:npts)=id2(1:npts)
     dd(npts+1:)=0.
     call timer('jt65a   ',0)

!     open(56,file='subtracted.wav',access='stream',status='unknown')
!     write(56) ihdr(1:11)

     call jt65a(dd,npts,newdat,nutc,nfa,nfb,nfqso,ntol,nsubmode, &
                minsync,nagain,n2pass,nrobust,ntrials, naggressive,ndepth, &
                nexp_decoded,ndecoded)
     call timer('jt65a   ',1)
  enddo

  call timer('jt65    ',1)
  call timer('jt65    ',101)
!  call four2a(a,-1,1,1,1)                  !Free the memory used for plans
!  call filbig(a,-1,1,0.0,0,0,0,0,0)        ! (ditto)
  go to 999

998 print*,'Cannot read from file:'
  print*,infile

999 end program jt65
