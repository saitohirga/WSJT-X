program jt9w

  parameter (NSMAX=6827,NZMAX=60*12000)
  real ss(184,NSMAX)
  real ref(NSMAX)
  integer*2 id2(NZMAX)
  character*12 arg

  call getarg(1,arg)
  read(arg,*) iutc

  open(20,file='refspec.dat',status='old')
  do i=1,NSMAX
     read(20,*) j,freq,ref(i)
  enddo

  do ifile=1,999
     read(60,end=999) nutc,nfqso,ntol,ndepth,nmode,nsubmode,ss,id2
     if(nutc.ne.iutc) cycle
     call decode9w(nutc,nfqso,ntol,nsubmode,ss,id2)
  enddo

999 end program jt9w
