program jt65

! Test the JT65 decoder for WSJT-X

  use options
  character c
logical :: display_help=.false.,err
  parameter (NZMAX=60*12000)
  integer*4 ihdr(11)
  integer*2 id2(NZMAX)
  real*4 dd(NZMAX)
  character*80 infile
  character(len=500) optarg
  common/tracer/limtrace,lu
  equivalence (lenfile,ihdr(2))
  type (option) :: long_options(3) = [ &
    option ('help',.false.,'h','Display this help message',''),      &
    option ('ntrials',.true.,'n','default=1000',''),                 &
    option ('single-signal mode',.false.,'s','default=1000','') ]

limtrace=0
lu=12
ntol=50
nfqso=1270
nagain=0
nsubmode=0
ntrials=10000
nlow=200
nhigh=4000
n2pass=2

  do
    call getopt('hn:s',long_options,c,optarg,narglen,nstat,noffset,nremain,err)
    if( nstat .ne. 0 ) then
      exit
    end if
    select case (c)
      case ('h')
        display_help = .true.
      case ('n')
        read (optarg(:narglen), *) ntrials
      case ('s')
        nlow=1250
        nhigh=1290
        n2pass=1
    end select
  end do

  nargs=iargc()
  if(display_help .or. (nargs.lt.1)) then
     print*,'Usage: jt65 [-n ntrials] [-s] file1 [file2 ...]'
     print*,'             -s single-signal mode'
     go to 999
  endif

  open(12,file='timer.out',status='unknown')
  call timer('jt65    ',0)

  ndecoded=0
  do ifile=1,nargs
     newdat=1
     nfa=nlow
     nfb=nhigh
     call getarg(ifile+noffset,infile)
     if( infile.eq.'' ) goto 900
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
                minsync,nagain,n2pass,ntrials, naggressive,ndepth,ndecoded)
     call timer('jt65a   ',1)
  enddo

900 call timer('jt65    ',1)
  call timer('jt65    ',101)
!  call four2a(a,-1,1,1,1)                  !Free the memory used for plans
!  call filbig(a,-1,1,0.0,0,0,0,0,0)        ! (ditto)
  go to 999

998 print*,'Cannot read from file:'
  print*,infile

999 end program jt65
