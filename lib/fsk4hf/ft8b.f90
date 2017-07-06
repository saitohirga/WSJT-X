subroutine ft8b(dd0,newdat,nfqso,f1,xdt,nharderrors,dmin,nbadcrc,message,xsnr)

  use timer_module, only: timer
  include 'ft8_params.f90'
  parameter(NRECENT=10,NP2=2812)
  character message*22,msgsent*22
  character*12 recent_calls(NRECENT)
  real a(5)
  real s1(0:7,ND),s2(0:7,NN)
  real ps(0:7)
  real rxdata(3*ND),llr(3*ND)               !Soft symbols
  real dd0(15*12000)
  integer*1 decoded(KK),apmask(3*ND),cw(3*ND)
  integer itone(NN)
  complex cd0(3125)
  complex ctwk(32)
  complex csymb(32)
  logical newdat

  max_iterations=40
  norder=2
  fs2=12000.0/64.0
  dt2=1.0/fs2
  twopi=8.0*atan(1.0)
  delfbest=0.
  ibest=0

!  if(abs(nfqso-f1).lt.10.0) norder=3
  call timer('ft8_down',0)
  call ft8_downsample(dd0,newdat,f1,cd0)   !Mix f1 to baseband and downsample
  call timer('ft8_down',1)

  i0=nint(xdt*fs2)                         !Initial guess for start of signal
  smax=0.0
  do idt=i0-16,i0+16                       !Search over +/- half a symbol
     call sync8d(cd0,idt,ctwk,0,sync)
     if(sync.gt.smax) then
        smax=sync
        ibest=idt
     endif
  enddo
  xdt2=ibest*dt2                           !Improved estimate for DT

! Now peak up in frequency
  i0=nint(xdt2*fs2)
  smax=0.0
  do ifr=-5,5                              !Search over +/- 2.5 Hz
    delf=ifr*0.5
    dphi=twopi*delf*dt2
    phi=0.0
    do i=1,32
      ctwk(i)=cmplx(cos(phi),sin(phi))
      phi=mod(phi+dphi,twopi)
    enddo
   call sync8d(cd0,i0,ctwk,1,sync)
    if( sync .gt. smax ) then
      smax=sync
      delfbest=delf
    endif
  enddo
  a=0.0
  a(1)=-delfbest
  call twkfreq1(cd0,NP2,fs2,a,cd0)
  xdt=xdt2
  f1=f1+delfbest                           !Improved estimate of DF

  call sync8d(cd0,i0,ctwk,2,sync)

  j=0
  do k=1,NN
    i1=ibest+(k-1)*32
    csymb=cmplx(0.0,0.0)
    if( i1.ge.1 .and. i1+31 .le. NP2 ) csymb=cd0(i1:i1+31)
    call four2a(csymb,32,1,-1,1)
    s2(0:7,k)=abs(csymb(1:8))
  enddo  
  j=0
  do k=1,NN
    if(k.le.7) cycle
    if(k.ge.37 .and. k.le.43) cycle
    if(k.gt.72) cycle
    j=j+1
    s1(0:7,j)=s2(0:7,k)
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
  call timer('bpd174  ',0)
  call bpdecode174(llr,apmask,max_iterations,decoded,cw,nharderrors)
  call timer('bpd174  ',1)
  dmin=0.0
  if(nharderrors.lt.0) then
     call timer('osd174  ',0)
     call osd174(llr,norder,decoded,cw,nharderrors,dmin)
     call timer('osd174  ',1)
  endif
  nbadcrc=1
  message='                      '
  xsnr=-99.0
  if(count(cw.eq.0).eq.174) go to 900           !Reject the all-zero codeword
  if( nharderrors.ge.0 .and. dmin.le.30.0 .and. nharderrors .lt. 30) then
    call chkcrc12a(decoded,nbadcrc)
  else
    nharderrors=-1
    go to 900
  endif
  if(nbadcrc.eq.0) then
     call extractmessage174(decoded,message,ncrcflag,recent_calls,nrecent)
     call genft8(message,msgsent,itone)
     xsig=0.0
     xnoi=0.0
     do i=1,79
        xsig=xsig+s2(itone(i),i)**2
        ios=mod(itone(i)+4,7)
        xnoi=xnoi+s2(ios,i)**2
     enddo
     xsnr=0.001
     if( xnoi.gt.0 .and. xnoi.lt.xsig ) xsnr=xsig/xnoi-1.0
     xsnr=10.0*log10(xsnr)-27.0
     if( xsnr .lt. -24.0 ) xsnr=-24.0
  endif

900 continue
  return
end subroutine ft8b
