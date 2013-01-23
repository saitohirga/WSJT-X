program wsjt24d

  real*4 dat(60*11025/2)
  character*6 cfile6
  character*12 arg
  real ccfblue(-5:540)        !X-cor function in JT65 mode (blue line)
  real ccfred(450)            !Average spectrum of the whole file
  integer dftolerance

  nargs=iargc()
  if(nargs.ne.2) then
     print*,'Usage: wspr24d ifile1 ifile2'
     go to 999
  endif
  call getarg(1,arg)
  read(arg,*) ifile1
  call getarg(2,arg)
  read(arg,*) ifile2

  open(23,file='CALL3.TXT',status='old')
  open(50,file='vk7mo.dat',form='unformatted',status='old')

  do ifile=1,ifile2
     read(50,end=999) jz,cfile6,NClearAve,MinSigdB,DFTolerance,NFreeze,  &
          mode,mode4,Nseg,MouseDF2,NAgain,idf,lumsg,lcum,nspecial,ndf,   &
          NSyncOK,dat(1:jz)
     if(ifile.lt.ifile1) cycle

!     write(*,3000) ifile,cfile6,jz,mode,mode4,idf
!3000 format(i3,2x,a6,i10,3i5)

     dftolerance=100
     nfreeze=1
     neme=0

!    call wsjt24(dat(4097),jz-4096,cfile6,NClearAve,MinSigdB,DFTolerance,  &
    call wsjt24(dat,jz,cfile6,NClearAve,MinSigdB,DFTolerance,             &
         NFreeze,mode,mode4,Nseg,MouseDF2,NAgain,idf,lumsg,lcum,nspecial, &
         ndf,NSyncOK,ccfblue,ccfred,ndiag)
    if(ifile.ge.ifile2) exit
  enddo

999 end program wsjt24d
