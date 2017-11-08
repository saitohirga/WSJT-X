program driver

  use dxped_fox
  character*22 rxmsg
  character cxx*6,gxx*4
  character*8 arg
  integer ntot(5),irate(5)

  open(10,file='xcall.txt',status='old')
  ntot=0
  irate=0
  MyCall='KH1DX'
  MyGrid='AJ10'
  nargs=iargc()
  ii1=1
  ii2=5
  jj1=0
  jj2=5
  if(nargs.eq.2) then
     call getarg(1,arg)
     read(arg,*) nsig
     call getarg(2,arg)
     read(arg,*) fail
     ii1=nsig
     ii2=nsig
     jj1=nint(10*fail)
     jj2=nint(10*fail)
  endif
  
  do jj=jj1,jj2
     fail=0.1*jj    
     do ii=ii1,ii2
        rewind 10
        nsig=ii
! Start with all istate = 0  
        istate=0
        nlogged=0
  
! Open the file of callers (this will be a FIFO)
        do iseq=0,80
           if(iand(iseq,1).eq.0) call fox_tx(iseq)
           if(iand(iseq,1).eq.1) then
              nrx=0
              do j=1,nsig
                 if(ichar(cx(j)(1:1)).ne.0) then
                    call random_number(x)
                    irpt=-20+int(40*x)
                    write(rxmsg,1000) MyCall,cx(j),irpt
1000                format(a6,1x,a6,' R',i3.2)
                    if(rxmsg(16:16).eq.' ') rxmsg(16:16)='+'
                 endif
                 if(iseq.eq.1) then
                    read(10,1002) cxx,gxx
1002                format(a6,7x,a4)
                    rxmsg='KH1DX  '//cxx//' '//gxx
                 endif
                 call random_number(x)
                 if(x.ge.fail .and. cx(j)(1:1).ne.' ') call fox_rx(iseq,rxmsg)
              enddo
              if(iseq.eq.1) rewind 10
           endif
        enddo
        ntot(ii)=nlogged
        irate(ii)=0
        if(iseq.gt.0) irate(ii)=nint(nlogged*240.0/iseq)
        write(*,3001) nsig,fail,nlogged
3001    format('Nsig:',i3,'   Fail:',f4.1,'   Logged QSOs:',i4)
     enddo
     write(13,1100) fail,ntot,irate
1100 format(f5.1,5i6,5x,5i6)
  enddo

end program driver
