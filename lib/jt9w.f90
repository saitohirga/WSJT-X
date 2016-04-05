program jt9w

  parameter (NSMAX=6827,NZMAX=60*12000)
  real ss(184,NSMAX)
  real ref(NSMAX)
  integer*2 id2(NZMAX)
  character*12 arg
  character*22 decoded

  call getarg(1,arg)
  read(arg,*) iutc

  open(20,file='refspec.dat',status='old')
  do i=1,NSMAX
     read(20,*) j,freq,ref(i)
  enddo

  do ifile=1,999
     read(60,end=999) nutc,nfqso,ntol,ndepth,nmode,nsubmode,ss,id2
     if(nutc.ne.iutc) cycle
     ntol=100
     call decode9w(nutc,nfqso,ntol,nsubmode,ss,id2,sync,nsnr,xdt,freq,decoded)
     write(*,1100) nutc,nsnr,xdt1-1.0,nint(freq),decoded
1100 format(i4.4,i4,f5.1,i5,1x,'@',1x,a22)
     exit
  enddo

999 end program jt9w
