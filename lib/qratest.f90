program qratest

  parameter (NMAX=60*12000) 
  real dd(NMAX)
  character*8 arg
  character*12 mycall,hiscall
  character*6 hisgrid
  character*22 decoded

  nargs=iargc()
  if(nargs.ne.3) then
     print*,'Usage: qratest f0 maxf1 fTol'
     go to 999
  endif
  call getarg(1,arg)
  read(arg,*) nf0
  call getarg(2,arg)
  read(arg,*) maxf1
  call getarg(3,arg)
  read(arg,*) ntol
  ndepth=3

!  do n=1,999
  do n=1,1
     read(60,end=999) dd,npts,nutc,nf1,nf2,nfqso,ntol,mode64,minsync,mycall, &
          hiscall,hisgrid
     call qra64a(dd,npts,nutc,nf1,nf2,nfqso,ntol,mode64,minsync,ndepth,      &
          mycall,hiscall,hisgrid,sync,nsnr,dtx,nfreq,decoded,nft)
     write(*,1000) nutc,nsnr,dtx,nfreq,decoded,nft-100
1000 format(i4.4,i4,f6.2,i5,1x,a22,i3)
  enddo

999 end program qratest
