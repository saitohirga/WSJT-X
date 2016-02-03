program jtmsk

 parameter (NMAX=359424)
  integer*2 id2(NMAX)
  integer narg(0:14)
  character*6 mycall,hiscall
  character*22 msg,arg*8
  character*80 line(100)
  character*60 line0
  character infile*80

  nargs=iargc()
  if(nargs.lt.4) then
     print*,'Usage: jtmsk MyCall HisCall ntol infile1 [infile2 ...]'
     go to 999
  endif
  call getarg(1,mycall)
  call getarg(2,hiscall)
  msg='<'//mycall//' '//hiscall//'> 26'
  call fmtmsg(msg,iz)
  call hash_calls(msg,narg(12))
  call getarg(3,arg)
  read(arg,*) ntol

  nfiles=nargs-3
  tsync1=0.
  tsync2=0.
  tsoft=0.
  tvit=0.
  ttotal=0.
  ndecodes=0

  call timer('jtmsk   ',0)
  do ifile=1,nfiles
     call getarg(ifile+3,infile)
     open(10,file=infile,access='stream',status='old')
     read(10) id2(1:22)                     !Skip 44 header bytes
     npts=179712                            !### T/R = 15 s
     read(10,end=1) id2(1:npts)             !Read the raw data
1    close(10)
     i1=index(infile,'.wav')
     read(infile(i1-6:i1-1),*) narg(0)

     nrxfreq=1500
     narg(1)=npts        !npts
     narg(2)=0           !nsubmode
     narg(3)=1           !newdat
     narg(4)=0           !minsync
     narg(5)=0           !npick
     narg(6)=0           !t0 (ms)
     narg(7)=npts/12     !t1 (ms) ???
     narg(8)=2           !maxlines
     narg(9)=103         !nmode
     narg(10)=nrxfreq
     narg(11)=ntol

     call timer('jtmsk_de',0)
     call jtmsk_decode(id2,narg,line)
     call timer('jtmsk_de',1)
     do i=1,narg(8)
        if(line(i)(1:1).eq.char(0)) exit
        ndecodes=ndecodes+1
        line0=line(i)(1:60)
        i1=index(line(i)(1:60),'<...>')
        if(i1.gt.0 .and. narg(13).eq.narg(12)) then
           i2=index(msg,'>')
           line0=line(i)(1:i1-1)//msg(1:i2)//line(i)(i1+5:i1+10)
        endif
        write(*,1002) line0,ndecodes
1002    format(a60,i10)
     enddo
  enddo

  call timer('jtmsk   ',1)
  call timer('jtmsk   ',101)

999 end program jtmsk
