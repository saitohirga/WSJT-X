subroutine ft8b(datetime,s,candidate,ncand)

  include 'ft8_params.f90'
  parameter(NRECENT=10)
  character*12 recent_calls(NRECENT)
  character message*22,datetime*13
  real s(NH1,NHSYM)
  real s1(0:7,ND)
  real ps(0:7)
  real rxdata(3*ND),llr(3*ND)               !Soft symbols
  real candidate(3,100)
  integer*1 decoded(KK),apmask(3*ND),cw(3*ND)

  max_iterations=40
  norder=2
  tstep=0.5*NSPS/12000.0
  df=12000.0/NFFT1

  do icand=1,ncand
     f1=candidate(1,icand)
     xdt=candidate(2,icand)
     sync=candidate(3,icand)
     i0=nint(f1/df)
     j0=nint(xdt/tstep)

     j=0
     ia=i0
     ib=i0+14
     do k=1,NN
        if(k.le.7) cycle
        if(k.ge.37 .and. k.le.43) cycle
        if(k.gt.72) cycle
        n=j0+2*(k-1)+1
        if(n.lt.1) cycle
        j=j+1
        s1(0:7,j)=s(ia:ib:2,n)
     enddo
     
     do j=1,ND
        ps=s1(0:7,j)
        ps=log(ps)
        r1=max(ps(1),ps(3),ps(5),ps(7))-max(ps(0),ps(2),ps(4),ps(6))
        r2=max(ps(2),ps(3),ps(6),ps(7))-max(ps(0),ps(1),ps(4),ps(5))
        r4=max(ps(4),ps(5),ps(6),ps(7))-max(ps(0),ps(1),ps(2),ps(3))
        rxdata(3*j-2)=r4
        rxdata(3*j-1)=r2
        rxdata(3*j)=r1
     enddo
     rxav=sum(rxdata)/ND
     rx2av=sum(rxdata*rxdata)/ND
     rxsig=sqrt(rx2av-rxav*rxav)
     rxdata=rxdata/rxsig
     ss=0.84
     llr=2.0*rxdata/(ss*ss)
     apmask=0
     call bpdecode174(llr,apmask,max_iterations,decoded,niterations)
     if(niterations.lt.0) call osd174(llr,norder,decoded,nharderrors,cw)
     nbadcrc=0
     call chkcrc12a(decoded,nbadcrc)

     message='                      '
     if(nbadcrc.eq.0) then
        call extractmessage174(decoded,message,ncrcflag,recent_calls,nrecent)
        nsnr=nint(10.0*log10(sync) - 25.5)    !### empirical ###
        write(13,1110) datetime,0,nsnr,xdt,f1,xdta,f1a,niterations,    &
             nharderrors,message
1110    format(a13,2i4,2(f6.2,f7.1),2i4,2x,a22)
        write(*,1112) datetime(8:13),nsnr,xdt,nint(f1),message
1112    format(a6,i4,f5.1,i6,2x,a22)
     endif
  enddo

  return
end subroutine ft8b
