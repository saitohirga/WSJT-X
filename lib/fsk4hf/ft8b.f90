subroutine ft8b(s,nfqso,f1,xdt,nharderrors,dmin,nbadcrc,message)

  use timer_module, only: timer
  include 'ft8_params.f90'
  parameter(NRECENT=10)
  character*12 recent_calls(NRECENT)
  character message*22
  real s(NH1,NHSYM)
  real s1(0:7,ND)
  real ps(0:7)
  real rxdata(3*ND),llr(3*ND)               !Soft symbols
  integer*1 decoded(KK),apmask(3*ND),cw(3*ND)

  max_iterations=40
  norder=2
!  if(abs(nfqso-f1).lt.10.0) norder=3
  tstep=0.5*NSPS/12000.0
  df=12000.0/NFFT1

  i0=max(1,nint(f1/df))
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
     where (ps.gt.0.0) ps=log(ps)
     r1=max(ps(1),ps(3),ps(5),ps(7))-max(ps(0),ps(2),ps(4),ps(6))
     r2=max(ps(2),ps(3),ps(6),ps(7))-max(ps(0),ps(1),ps(4),ps(5))
     r4=max(ps(4),ps(5),ps(6),ps(7))-max(ps(0),ps(1),ps(2),ps(3))
     rxdata(3*j-2)=r4
     rxdata(3*j-1)=r2
     rxdata(3*j)=r1
  enddo

  rxav=sum(rxdata)/(3.0*ND)
  rx2av=sum(rxdata*rxdata)/(3.0*ND)
  var=rx2av-rxav*rxav
  if( var .gt. 0.0 ) then
     rxsig=sqrt(var)
  else
     rxsig=sqrt(rx2av)
  endif
  rxdata=rxdata/rxsig
  ss=0.84
  llr=2.0*rxdata/(ss*ss)
  apmask=0
  cw=0
! cw will be needed for subtraction.
! dmin is the correlation discrepancy of a returned codeword - it is 
!      used to select the best codeword within osd174.
  call timer('bpd174  ',0)
  call bpdecode174(llr,apmask,max_iterations,decoded,cw,nharderrors)
  call timer('bpd174  ',1)
  dmin=0.0
  if(nharderrors.lt.0) then
     call timer('osd174  ',0)
     call osd174(llr,norder,decoded,cw,nharderrors,dmin)
     call timer('osd174  ',1)
! This threshold needs to be tuned. 99.0 should pass everything.
     if( dmin .gt. 99.0 ) nharderrors=-1
  endif
  nbadcrc=1
  message='                      '
  if(count(cw.eq.0).eq.174) go to 900           !Reject the all-zero codeword
  if(nharderrors.ge.0) call chkcrc12a(decoded,nbadcrc)
  if(nbadcrc.eq.0) then
     call extractmessage174(decoded,message,ncrcflag,recent_calls,nrecent)
  endif
900 continue

  return
end subroutine ft8b
