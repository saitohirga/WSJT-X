program jt65

  ! Test the JT65 decoder for WSJT-X

  use options
  use timer_module, only: timer
  use timer_impl, only: init_timer
  use jt65_test
  use readwav

  character c
  logical :: display_help=.false.,nrobust=.false.
  type(wav_header) :: wav
  integer*2 id2(NZMAX)
  real*4 dd(NZMAX)
  character*80 infile
  character(len=500) optarg
  character*12 mycall,hiscall
  character*6 hisgrid
  type (option) :: long_options(10) = [ &
       option ('aggressive',.true.,'a','aggressiveness [0-10], default AGGR=0','AGGR'), &
       option ('freq',.true.,'f','signal frequency, default FREQ=1270','FREQ'),         &
       option ('help',.false.,'h','Display this help message',''),                      &
       option ('ntrials',.true.,'n','number of trials, default TRIALS=10000','TRIALS'), &
       option ('robust-sync',.false.,'r','robust sync',''),                             &
       option ('my-call',.true.,'c','my callsign',''),                                  &
       option ('his-call',.true.,'x','his callsign',''),                                &
       option ('his-grid',.true.,'g','his grid locator',''),                            &
       option ('experience-decoding',.true.,'X'                                         &
               ,'experience decoding options (1..n), default FLAGS=0','FLAGS'),         &
       option ('single-signal-mode',.false.,'s','decode at signal frequency only','') ]

  naggressive=0
  nfqso=1270
  ntrials=10000
  nexp_decoded=0
  ntol=1000
  nsubmode=0
  nlow=200
  nhigh=4000
  n2pass=2

  do
     call getopt('a:f:hn:rc:x:g:X:s',long_options,c,optarg,narglen,nstat,noffset,nremain,.true.)
     if( nstat .ne. 0 ) then
        exit
     end if
     select case (c)
     case ('a')
        read (optarg(:narglen), *) naggressive
     case ('f')
        read (optarg(:narglen), *) nfqso
     case ('h')
        display_help = .true.
     case ('n')
        read (optarg(:narglen), *) ntrials
     case ('r')
        nrobust=.true.
     case ('c')
        read (optarg(:narglen), *) mycall
     case ('x')
        read (optarg(:narglen), *) hiscall
     case ('g')
        read (optarg(:narglen), *) hisgrid
     case ('X')
        read (optarg(:narglen), *) nexp_decoded
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

  call init_timer ('timer.out')
  call timer('jt65    ',0)

  ndecoded=0
  do ifile=noffset+1,noffset+nremain
     nfa=nlow
     nfb=nhigh
     minsync=0
     call get_command_argument(ifile,optarg,narglen)
     infile=optarg(:narglen)
     call timer('read    ',0)
     call wav%read (infile)
     i1=index(infile,'.wav')
     if( i1 .eq. 0 ) i1=index(infile,'.WAV')
     read(infile(i1-4:i1-1),*,err=998) nutc
     npts=52*12000
     read(unit=wav%lun) id2(1:npts)
     close(unit=wav%lun)
     call timer('read    ',1)
     dd(1:npts)=id2(1:npts)
     dd(npts+1:)=0.
     call test(dd,nutc,nfa,nfb,nfqso,ntol,nsubmode, &
          n2pass,nrobust,ntrials,naggressive, &
          mycall,hiscall,hisgrid,nexp_decoded)
  enddo

  call timer('jt65    ',1)
  call timer('jt65    ',101)
  !  call four2a(a,-1,1,1,1)                  !Free the memory used for plans
  !  call filbig(a,-1,1,0.0,0,0,0,0,0)        ! (ditto)
  go to 999

998 print*,'Cannot read from file:'
  print*,infile

999 continue
end program jt65
