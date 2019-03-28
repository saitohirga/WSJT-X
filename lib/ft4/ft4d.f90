program ft4d

   include 'ft4_params.f90'
   character*8 arg
   character*17 cdatetime 
   character*512 data_dir
   character*12 mycall
   character*12 hiscall
   character*80 infile
   character*61 line
   character*4  cqstr
   real*8 fMHz
   integer ihdr(11)
   integer*2 iwave(240000)                !20*12000

   fs=12000.0/NDOWN                       !Sample rate
   dt=1/fs                                !Sample interval after downsample (s)
   tt=NSPS*dt                             !Duration of "itone" symbols (s)
   baud=1.0/tt                            !Keying rate for "itone" symbols (baud)
   txt=NZ*dt                              !Transmission length (s)

   nargs=iargc()
   if(nargs.lt.1) then
      print*,'Usage:   ft4d [-a <data_dir>] [-f fMHz] [-n nQSOProgress] file1 [file2 ...]'
      go to 999
   endif
   iarg=1
   data_dir="."
   call getarg(iarg,arg)
   if(arg(1:2).eq.'-a') then
      call getarg(iarg+1,data_dir)
      iarg=iarg+2
   endif
   call getarg(iarg,arg)
   if(arg(1:2).eq.'-f') then
      call getarg(iarg+1,arg)
      read(arg,*) fMHz
      iarg=iarg+2
   endif
   nQSOProgress=0
   if(arg(1:2).eq.'-n') then
      call getarg(iarg+1,arg)
      read(arg,*) nQSOProgress 
      iarg=iarg+2
   endif
   nfa=10
   nfb=4990
   ndecodes=0
   nfqso=1500
   mycall="K9AN"
   hiscall="K1JT"
   ncontest=4
   cqstr="RU  "

   do ifile=iarg,nargs
      call getarg(ifile,infile)
      j2=index(infile,'.wav')
      open(10,file=infile,status='old',access='stream')
      read(10) ihdr
      npts=ihdr(11)/2
      read(10) iwave(1:npts)
      close(10)
      cdatetime=infile(1:13)//'.000'

      istep=3456
      nsteps=(npts-52800)/istep + 1
      do n=1,nsteps
         i0=(n-1)*istep + 1
         tbuf=(i0-1)/12000.0
         call ft4_decode(cdatetime,tbuf,nfa,nfb,nQSOProgress,ncontest,    &
              nfqso,iwave(i0),ndecodes,mycall,hiscall,cqstr,line,data_dir)
         do idecode=1,ndecodes
            call get_ft4msg(idecode,line)
            write(*,'(a61)') line
         enddo
      enddo        !steps
   enddo           !files

   call four2a(xx,-1,1,-1,1)   !Destroy FFTW plans to free their memory

999 end program ft4d


