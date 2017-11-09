program fox_sim

! Simulates QSO exchanges using the proposed FT8 "DXpedition" mode.

  parameter (MAXSIG=5,NCALLS=268)  
  character*6 xcall(NCALLS)
  character*4 xgrid(NCALLS)
  integer isnr(NCALLS)

  character*32 fmsg(MAXSIG),fm
  character*22 hmsg(MAXSIG),hm
  character*16 log
  character*6 called(MAXSIG)
  character*4 gcalled(MAXSIG)
  character*6 MyCall
  character*4 MyGrid
  character*8 arg
  integer ntot(MAXSIG),irate(MAXSIG),ntimes(MAXSIG)
  logical logit
  common/dxpfifo/nc,isnr,xcall,xgrid
  
  nargs=iargc()
  if(nargs.ne.2 .and. nargs.ne.4) then
     print*,'Usage: fox_sim  nseq maxtimes'
     print*,'       fox_sim  nseq maxtimes nsig fail'                    
     go to 999
  endif
  ii1=1
  ii2=5
  jj1=0
  jj2=5
  nseq=80
  if(nargs.ge.2) then
     call getarg(1,arg)
     read(arg,*) nseq
     call getarg(2,arg)
     read(arg,*) maxtimes
  endif
  if(nargs.eq.4) then
     call getarg(3,arg)
     read(arg,*) nsig
     call getarg(4,arg)
     read(arg,*) fail
     ii1=nsig
     ii2=nsig
     jj1=nint(10*fail)
     jj2=nint(10*fail)
  endif

! Read a file with calls and grids; insert random S/N values.
! This is used in place of an operator-selected FIFO
  open(10,file='xcall.txt',status='old')
  do i=1,NCALLS
     read(10,1000) xcall(i),xgrid(i)
1000 format(a6,7x,a4)
     call random_number(x)
     isnr(i)=-20+int(40*x)
  enddo
  close(10)

  minutes=nseq/4
  write(13,1002) nseq,minutes,maxtimes
1002 format(/'Nseq:',i4,'   Minutes:',i3,'   Maxtimes:',i2)

  ntot=0
  irate=0
  MyCall='KH1DX'
  MyGrid='AJ10'

  do jj=jj1,jj2
     fail=0.1*jj    
     do ii=ii1,ii2
        nc=0                           !Set FIFO pointer to top
        ntimes=1
        nsig=ii
        nlogged=0
        fmsg="CQ KH1DX AJ10"
        hmsg=""
        called="      "
        do iseq=0,nseq
           if(iand(iseq,1).eq.0) then
              do j=1,nsig
                 fm=fmsg(j)
                 hm=hmsg(j)
                 call fox_tx(maxtimes,fail,called(j),gcalled(j),hm,fm,    &
                      ntimes(j),log,logit)
                 fmsg(j)=fm
                 if(logit) then
                    nlogged=nlogged+1
                    nrate=0
                    if(iseq.gt.0) nrate=nint(nlogged*240.0/iseq)
                    write(*,1010) iseq,j,ntimes(j),fmsg(j),log,nlogged,nrate
1010                format(i4.4,2i2,1x,a32,20x,a16,2i4)
                 else
                    write(*,1010) iseq,j,ntimes(j),fmsg(j)
!                    write(fmsg(j),1004) cx(j),mycall,irpt(j)
!                    write(*,1010) iseq,j,istate(1:2,j),fmsg(j)
                 endif
!                 if(fm(1:3).eq.'2E0') print*,'tx a0',j,fm,called(j)
              enddo
              ! call transmit
           endif
           
           if(iand(iseq,1).eq.1) then
              do j=1,nsig
                 fm=fmsg(j)
!                 print*,'AA ',j,fm,called(j)
                 call fox_rx(fail,called(j),fm,hm)
                 hmsg(j)=hm
!                 print*,'BB ',j,fm,called(j),' ',hm
                 write(*,1020) iseq,j,hmsg(j)
1020             format(i4.4,i2,37x,a22)
              enddo
           endif
        enddo
        ntot(ii)=nlogged
        irate(ii)=0
        if(iseq.gt.0) irate(ii)=nint(nlogged*3600.0/(15*iseq))
        write(*,3001) nsig,fail,nlogged
3001    format('Nsig:',i3,'   Fail:',f4.1,'   Logged QSOs:',i4)
     enddo
     write(13,1100) fail,ntot,irate
1100 format(f5.1,5i6,5x,5i6)
  enddo

999 end program fox_sim
