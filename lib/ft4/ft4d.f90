program ft4d

   include 'ft4_params.f90'

   character*8 arg
   character*17 cdatetime 
   character*512 data_dir
   character*11 datetime
   character*37 decodes(100)
   character*16 fname
   character*6 hiscall
   character*80 infile
   character*61 line
   character*6 mycall
   
   real*8 fMHz

   integer ihdr(11)
   integer*2 iwave(NMAX)                 !Generated full-length waveform

   fs=12000.0/NDOWN                       !Sample rate
   dt=1/fs                                !Sample interval after downsample (s)
   tt=NSPS*dt                             !Duration of "itone" symbols (s)
   baud=1.0/tt                            !Keying rate for "itone" symbols (baud)
   txt=NZ*dt                              !Transmission length (s)

   nargs=iargc()
   if(nargs.lt.1) then
      print*,'Usage:   ft4d [-a <data_dir>] [-f fMHz] file1 [file2 ...]'
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
   nfa=200
   nfb=3000
   nQSOProgress=0

   do ifile=iarg,nargs
      call getarg(ifile,infile)
      j2=index(infile,'.wav')
      open(10,file=infile,status='old',access='stream')
      read(10,end=999) ihdr,iwave
      read(infile(j2-4:j2-1),*) nutc
      datetime=infile(j2-11:j2-1)
      cdatetime='      '//datetime
      close(10)

      call ft4_decode(cdatetime,0.0,nfa,nfb,nQSOProgress,nfqso,iwave,ndecodes,mycall,    &
           hiscall,nrx,line,data_dir)
      
      do idecode=1,ndecodes
         call get_ft4msg(idecode,nrx,line)
         write(*,'(a61)') line
      enddo
   enddo !files

   write(*,1120)
1120 format("<DecodeFinished>")

999 end program ft4d


