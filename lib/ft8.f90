program ft8

  integer*2 iwave(15*12000)
  logical lft8apon,lapcqonly,nagain,newdat
  character*12 mycall12,hiscall12
  character*6 hisgrid6
  character arg*8,infile*80
  integer ihdr(11)

  nargs=iargc()
  if(nargs.lt.3) then
     print*,'Usage:   ft8 nfa  nfb ndepth    infile'
     print*,'Example: ft8 200 4000   3  181201_180315.wav'
     go to 999
  endif
  call getarg(1,arg)
  read(arg,*) nfa
  call getarg(2,arg)
  read(arg,*) nfb
  call getarg(3,arg)
  read(arg,*) ndepth
  nfiles=nargs-3

  nQSOProgress=0
  nfqso=1500
  nftx=0
  newdat=.true.
  nutc=0
  ncontest=0
  nagain=.false.
  lft8apon=.false.
  lapcqonly=.false.
  napwid=75
  mycall12='K1ABC'
  hiscall12='W9XYZ'
  hisgrid6='EN37wb'

  do ifile=1,nfiles
     call getarg(3+ifile,infile)
     open(10,file=infile,status='old',access='stream')
     read(10) ihdr,iwave
     close(10)

     call ft8dec(iwave,nQSOProgress,nfqso,nftx,newdat,            &
          nutc,nfa,nfb,ndepth,ncontest,nagain,lft8apon,lapcqonly, &
          napwid,mycall12,hiscall12,hisgrid6)
  enddo

999 end program ft8
