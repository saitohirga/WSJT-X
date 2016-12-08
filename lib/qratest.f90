program qratest

  parameter (NMAX=60*12000) 
  real dd(NMAX)
  character arg*8,mycall*12,hiscall*12,hisgrid*6,decoded*22
  character c*1,label*3

  nargs=iargc()
  if(nargs.lt.1 .or. nargs.gt.3) then
     print*,'Usage: qratest nfile [f0 fTol]'
     go to 999
  endif
  call getarg(1,arg)
  read(arg,*) nfile
  if(nargs.gt.1) then
     call getarg(2,arg)
     read(arg,*) maxf1
     call getarg(3,arg)
     read(arg,*) ntol
  endif
  ndepth=3
  nft=99
  
  open(60,file='qra64_data.bin',access='stream')

  do ifile=1,999
     read(60,end=999) dd,npts,nutc,nf1,nf2,nfqso,ntol,mode64,minsync,ndepth, &
          mycall,hiscall,hisgrid
     if(ifile.lt.nfile) cycle
     call qra64a(dd,npts,nutc,nf1,nf2,nfqso,ntol,mode64,minsync,ndepth,      &
          mycall,hiscall,hisgrid,sync,nsnr,dtx,nfreq,decoded,nft)
     c='a'
     if(mode64.eq.2) c='b'
     if(mode64.eq.4) c='c'
     if(mode64.eq.8) c='d'
     if(mode64.eq.16) c='e'
     write(*,1000) ifile,c,nutc,nsnr,dtx,nfreq,decoded,nft-100
1000 format(i4,1x,a1,1x,i4.4,i4,f6.2,i5,1x,a22,i3)
     if(ifile.eq.nfile) exit
  enddo

999 end program qratest
