program msk144d

  ! Test the msk144 decoder for WSJT-X

  use options
  use timer_module, only: timer
  use timer_impl, only: init_timer
  use readwav

  character c
  character*80 line(100)
  character*512 pchk_file
  logical :: display_help=.false.
  type(wav_header) :: wav
  integer*2 id2(30*12000)
  character*500 infile
  character*12 mycall,hiscall
  character(len=500) optarg

  type (option) :: long_options(3) = [ &
       option ('help',.false.,'h','Display this help message',''), &
       option ('mycall',.true.,'c','mycall',''), &
       option ('hiscall',.true.,'x','hiscall','') &  
       ]
  do
     call getopt('c:hx:',long_options,c,optarg,narglen,nstat,noffset,nremain,.true.)
     if( nstat .ne. 0 ) then
        exit
     end if
     select case (c)
     case ('h')
        display_help = .true.
     case ('n')
        read (optarg(:narglen), *) ntrials
     case ('c')
        read (optarg(:narglen), *) mycall
     case ('x')
        read (optarg(:narglen), *) hiscall
     end select
  end do

  if(display_help .or. nstat.lt.0 .or. nremain.lt.1) then
     print *, ''
     print *, 'Usage: msk144d [OPTIONS] file1 [file2 ...]'
     print *, ''
     print *, '       msk144 decode pre-recorded .WAV file(s)'
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

  pchk_file='./peg-128-80-reg3.pchk'
  ndecoded=0
  do ifile=noffset+1,noffset+nremain
     call get_command_argument(ifile,optarg,narglen)
     infile=optarg(:narglen)
     call timer('read    ',0)
     call wav%read (infile)
     i1=index(infile,'.wav')
     if( i1 .eq. 0 ) i1=index(infile,'.WAV')
     read(infile(i1-6:i1-1),*,err=998) nutc
     inquire(FILE=infile,SIZE=isize)
     npts=min((isize-216)/2,360000)
     read(unit=wav%lun) id2(1:npts)
     close(unit=wav%lun)
     call timer('read    ',1)
     call msk144_decode(id2,npts,nutc,1,pchk_file,mycall,hiscall,line)
  enddo

  call timer('msk144    ',1)
  call timer('msk144    ',101)
  go to 999

998 print*,'Cannot read from file:'
  print*,infile

999 continue
end program msk144d
