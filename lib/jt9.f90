program jt9

! Decoder for JT9.  Can run stand-alone, reading data from *.wav files;
! or as the back end of wsjt-x, with data placed in a shared memory region.

  use options
  use prog_args
  use, intrinsic :: iso_c_binding
  use FFTW3

  include 'constants.f90'
  integer(C_INT) iret
  integer*4 ihdr(11)
  real*4 s(NSMAX)
  integer*2 id2
  character c
  character(len=500) optarg, infile
  character wisfile*80
  integer*4 arglen,stat,offset,remain
  logical :: shmem = .false., read_files = .false., have_args = .false.
  type (option) :: long_options (0)
  common/jt9com/ss(184,NSMAX),savg(NSMAX),id2(NMAX),nutc,ndiskdat,ntr,       &
       mousefqso,newdat,nfa,nfsplit,nfb,ntol,kin,nzhsym,nsynced,ndecoded
  common/tracer/limtrace,lu
  common/patience/npatience,nthreads
  data npatience/1/,nthreads/1/

  do
     call getopt('s:e:a:r:m:p:d:f:w:t:',long_options,c,optarg,arglen,stat,     &
          offset,remain)
     if (stat .ne. 0) then
        exit
     end if
     have_args = .true.
     select case (c)
        case ('s')
           shmem = .true.
           shm_key = optarg(:arglen)

        case ('e')
           exe_dir = optarg(:arglen)

        case ('a')
           data_dir = optarg(:arglen)

        case ('t')
           temp_dir = optarg(:arglen)

        case ('m')
           read (optarg(:arglen), *) nthreads

        case ('p')
           read_files = .true.
           read (optarg(:arglen), *) ntrperiod

        case ('d')
           read_files = .true.
           read (optarg(:arglen), *) ndepth

        case ('f')
           read_files = .true.
           read (optarg(:arglen), *) nrxfreq

        case ('w')
           read (optarg(:arglen), *) npatience

     end select
  end do

  if (.not. have_args .or. (stat .lt. 0 .or. (shmem .and. remain .gt. 0)   &
       .or. (read_files .and. remain .eq. 0) .or.                          &
       (shmem .and. read_files))) then
     print*,'Usage: jt9 -p TRperiod [-d ndepth] [-f rxfreq] {-w patience] [-e exe_dir] [-m nthreads]  file1 [file2 ...]'
     print*,'       Reads data from *.wav files.'
     print*,''
     print*,'       jt9 -s <key> [-w patience] [-m nthreads] -e exe_dir -a data_dir -t temp_dir'
     print*,'       Gets data from shared memory region with key==<key>'
     go to 999
  endif

  iret=fftwf_init_threads()                   !Initialize FFTW threading 
  call fftwf_plan_with_nthreads(nthreads)
! Import FFTW wisdom, if available
  wisfile=trim(data_dir)//'/jt9_wisdom.dat'// C_NULL_CHAR
  iret=fftwf_import_wisdom_from_filename(wisfile)

  if (shmem) then
     call jt9a()
     go to 999
  endif

  limtrace=0
  lu=12

  do iarg = offset + 1, offset + remain
     call get_command_argument (iarg, optarg, arglen)
     infile = optarg(:arglen)
     open(10,file=infile,access='stream',status='old',err=998)
     read(10) ihdr
     nutc0=ihdr(1)                           !Silence compiler warning
     i1=index(infile,'.wav')
     read(infile(i1-4:i1-1),*,err=1) nutc0
     go to 2
1    nutc0=0
2    nsps=0
     if(ntrperiod.eq.1)  then
        nsps=6912
        nzhsym=173
     else if(ntrperiod.eq.2)  then
        nsps=15360
        nzhsym=178
     else if(ntrperiod.eq.5)  then
        nsps=40960
        nzhsym=172
     else if(ntrperiod.eq.10) then
        nsps=82944
        nzhsym=171
     else if(ntrperiod.eq.30) then
        nsps=252000
        nzhsym=167
     endif
     if(nsps.eq.0) stop 'Error: bad TRperiod'

     kstep=nsps/2
     k=0
     nhsym0=-999
     npts=(60*ntrperiod-6)*12000
     if(iarg .eq. offset + 1) then
        open(12,file=trim(data_dir)//'/timer.out',status='unknown')
        call timer('jt9     ',0)
     endif

     id2=0                               !??? Why is this necessary ???

     do iblk=1,npts/kstep
        k=iblk*kstep
        call timer('read_wav',0)
        read(10,end=10) id2(k-kstep+1:k)
        call timer('read_wav',1)

        nhsym=(k-2048)/kstep
        if(nhsym.ge.1 .and. nhsym.ne.nhsym0) then
! Emit signal readyForFFT
           ingain=0
           call timer('symspec ',0)
           call symspec(k,ntrperiod,nsps,ingain,slope,pxdb,s,df3,ihsym,npts8)
           call timer('symspec ',1)
           nhsym0=nhsym
           if(ihsym.ge.173) go to 10
        endif
     enddo

10   close(10)
     call fillcom(nutc0,ndepth,nrxfreq)
     call decoder(ss,id2)
  enddo

  call timer('jt9     ',1)
  call timer('jt9     ',101)
  go to 999

998 print*,'Cannot open file:'
  print*,infile

999 continue
  iret=fftwf_export_wisdom_to_filename(wisfile)

 call four2a(a,-1,1,1,1)                  !Save wisdom and free memory 
 call filbig(a,-1,1,0.0,0,0,0,0,0)        !used for FFT plans

end program jt9
