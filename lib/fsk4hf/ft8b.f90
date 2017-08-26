subroutine ft8b(dd0,newdat,nQSOProgress,nfqso,nftx,ndepth,lapon,napwid,       &
     lsubtract,nagain,iaptype,mygrid6,bcontest,sync0,f1,xdt,xbase,apsym,      &
     nharderrors,dmin,nbadcrc,ipass,iera,message,xsnr)  

  use timer_module, only: timer
  include 'ft8_params.f90'
  parameter(NRECENT=10,NP2=2812)
  character message*22,msgsent*22
  character*12 recent_calls(NRECENT)
  character*6 mygrid6
  logical bcontest
  real a(5)
  real s1(0:7,ND),s2(0:7,NN)
  real ps(0:7)
  real bmeta(3*ND),bmetap(3*ND)
  real llr(3*ND),llra(3*ND),llr0(3*ND),llrap(3*ND)           !Soft symbols
  real dd0(15*12000)
  integer*1 decoded(KK),apmask(3*ND),cw(3*ND)
  integer*1 msgbits(KK)
  integer apsym(KK)
  integer mcq(28),mde(28),mrrr(16),m73(16),mrr73(16)
  integer itone(NN)
  integer icos7(0:6),ip(1)
  integer nappasses(0:5)  ! the number of decoding passes to use for each QSO state
  integer naptypes(0:5,4) ! (nQSOProgress, decoding pass)  maximum of 4 passes for now
  complex cd0(3200)
  complex ctwk(32)
  complex csymb(32)
  logical first,newdat,lsubtract,lapon,nagain
  data icos7/2,5,6,0,4,1,3/
  data mcq/1,1,1,1,1,0,1,0,0,0,0,0,1,0,0,0,0,0,1,1,0,0,0,1,1,0,0,1/
  data mrrr/0,1,1,1,1,1,1,0,1,1,0,0,1,1,1,1/
  data m73/0,1,1,1,1,1,1,0,1,1,0,1,0,0,0,0/
  data mde/1,1,1,1,1,1,1,1,0,1,1,0,0,1,0,0,0,0,0,1,1,1,0,1,0,0,0,1/
  data mrr73/0,0,0,0,0,0,1,0,0,0,0,1,0,1,0,1/
  data first/.true./
  save nappasses,naptypes

  if(first) then
     mcq=2*mcq-1
     mde=2*mde-1
     mrrr=2*mrrr-1
     m73=2*m73-1
     mrr73=2*mrr73-1
     nappasses(0)=2
     nappasses(1)=2
     nappasses(2)=2
     nappasses(3)=4
     nappasses(4)=4
     nappasses(5)=3

! iaptype
!------------------------
!   1        CQ     ???    ???
!   2        MyCall ???    ???
!   3        MyCall DxCall ???
!   4        MyCall DxCall RRR
!   5        MyCall DxCall 73
!   6        MyCall DxCall RR73
!   7        ???    DxCall ???

     naptypes(0,1:4)=(/1,2,0,0/)
     naptypes(1,1:4)=(/2,3,0,0/)
     naptypes(2,1:4)=(/2,3,0,0/)
     naptypes(3,1:4)=(/3,4,5,6/)
     naptypes(4,1:4)=(/3,4,5,6/)
     naptypes(5,1:4)=(/3,1,2,0/)  !?
     first=.false.
  endif

  max_iterations=30
  nharderrors=-1
  fs2=12000.0/NDOWN
  dt2=1.0/fs2
  twopi=8.0*atan(1.0)
  delfbest=0.
  ibest=0

  call timer('ft8_down',0)
  call ft8_downsample(dd0,newdat,f1,cd0)   !Mix f1 to baseband and downsample
  call timer('ft8_down',1)

  i0=nint((xdt+0.5)*fs2)                   !Initial guess for start of signal
  smax=0.0
  do idt=i0-8,i0+8                         !Search over +/- one quarter symbol
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
    s2(0:7,k)=abs(csymb(1:8))/1e3
  enddo  

! sync quality check
  is1=0
  is2=0
  is3=0
  do k=1,7
    ip=maxloc(s2(:,k))
    if(icos7(k-1).eq.(ip(1)-1)) is1=is1+1
    ip=maxloc(s2(:,k+36))
    if(icos7(k-1).eq.(ip(1)-1)) is2=is2+1
    ip=maxloc(s2(:,k+72))
    if(icos7(k-1).eq.(ip(1)-1)) is3=is3+1
  enddo
! hard sync sum - max is 21
  nsync=is1+is2+is3
  if(nsync .le. 6) then ! bail out
    nbadcrc=1
    return
  endif

  j=0
  do k=1,NN
     if(k.le.7) cycle
     if(k.ge.37 .and. k.le.43) cycle
     if(k.gt.72) cycle
     j=j+1
     s1(0:7,j)=s2(0:7,k)
  enddo  

  do j=1,ND
     i4=3*j-2
     i2=3*j-1
     i1=3*j
     ps=s1(0:7,j)
     r1=max(ps(1),ps(3),ps(5),ps(7))-max(ps(0),ps(2),ps(4),ps(6))
     r2=max(ps(2),ps(3),ps(6),ps(7))-max(ps(0),ps(1),ps(4),ps(5))
     r4=max(ps(4),ps(5),ps(6),ps(7))-max(ps(0),ps(1),ps(2),ps(3))
     bmeta(i4)=r4
     bmeta(i2)=r2
     bmeta(i1)=r1
     bmetap(i4)=r4
     bmetap(i2)=r2
     bmetap(i1)=r1

     if(nQSOProgress .eq. 0 .or. nQSOProgress .eq. 5) then
! When bits 88:115 are set as ap bits, bit 115 lives in symbol 39 along
! with no-ap bits 116 and 117. Take care of metrics for bits 116 and 117.
        if(j.eq.39) then  ! take care of bits that live in symbol 39
           if(apsym(28).lt.0) then
              bmetap(i2)=max(ps(2),ps(3))-max(ps(0),ps(1))
              bmetap(i1)=max(ps(1),ps(3))-max(ps(0),ps(2))
           else 
              bmetap(i2)=max(ps(6),ps(7))-max(ps(4),ps(5))
              bmetap(i1)=max(ps(5),ps(7))-max(ps(4),ps(6))
           endif
        endif
     endif

! When bits 116:143 are set as ap bits, bit 115 lives in symbol 39 along
! with ap bits 116 and 117. Take care of metric for bit 115.
!        if(j.eq.39) then  ! take care of bit 115
!           iii=2*(apsym(29)+1)/2 + (apsym(30)+1)/2  ! known values of bits 116 & 117
!           if(iii.eq.0) bmetap(i4)=ps(4)-ps(0)
!           if(iii.eq.1) bmetap(i4)=ps(5)-ps(1)
!           if(iii.eq.2) bmetap(i4)=ps(6)-ps(2)
!           if(iii.eq.3) bmetap(i4)=ps(7)-ps(3)
!        endif

! bit 144 lives in symbol 48 and will be 1 if it is set as an ap bit.
! take care of metrics for bits 142 and 143
     if(j.eq.48) then  ! bit 144 is always 1
       bmetap(i4)=max(ps(5),ps(7))-max(ps(1),ps(3))
       bmetap(i2)=max(ps(3),ps(7))-max(ps(1),ps(5))
     endif 

! bit 154 lives in symbol 52 and will be 0 if it is set as an ap bit
! take care of metrics for bits 155 and 156
     if(j.eq.52) then  ! bit 154 will be 0 if it is set as an ap bit.
        bmetap(i2)=max(ps(2),ps(3))-max(ps(0),ps(1))
        bmetap(i1)=max(ps(1),ps(3))-max(ps(0),ps(2))
     endif  

  enddo

  call normalizebmet(bmeta,3*ND)
  call normalizebmet(bmetap,3*ND)

  ss=0.84
  llr0=2.0*bmeta/(ss*ss)
  llra=2.0*bmetap/(ss*ss)  ! llr's for use with ap
  apmag=4.0

! pass #
!------------------------------
!   1        regular decoding
!   2        erase 24
!   3        erase 48
!   4        ap pass 1
!   5        ap pass 2
!   6        ap pass 3
!   7        ap pass 4, etc.

  if(lapon) then 
     npasses=3+nappasses(nQSOProgress)
  else
     npasses=3
  endif

  do ipass=1,npasses 
               
     llr=llr0
     if(ipass.eq.2) llr(1:24)=0. 
     if(ipass.eq.3) llr(1:48)=0. 
     if(ipass.le.3) then
        apmask=0
        llrap=llr
        iaptype=0
     endif
        
     if(ipass .gt. 3) then
        iaptype=naptypes(nQSOProgress,ipass-3)
        if(iaptype.ge.3 .and. (abs(f1-nfqso).gt.napwid .and. abs(f1-nftx).gt.napwid) ) cycle 
        if(iaptype.eq.1 .or. iaptype.eq.2 ) then ! AP,???,??? 
           apmask=0
           apmask(88:115)=1    ! first 28 bits are AP
           apmask(144)=1       ! not free text
           llrap=llr
           if(iaptype.eq.1) llrap(88:115)=apmag*mcq/ss
           if(iaptype.eq.2) llrap(88:115)=apmag*apsym(1:28)/ss
           llrap(116:117)=llra(116:117)  
           llrap(142:143)=llra(142:143)
           llrap(144)=-apmag/ss
        endif
        if(iaptype.eq.3) then   ! mycall, dxcall, ???
           apmask=0
           apmask(88:115)=1   ! mycall
           apmask(116:143)=1  ! hiscall
           apmask(144)=1      ! not free text
           llrap=llr
           llrap(88:143)=apmag*apsym(1:56)/ss
           llrap(144)=-apmag/ss
        endif
        if(iaptype.eq.4 .or. iaptype.eq.5 .or. iaptype.eq.6) then  
           apmask=0
           apmask(88:115)=1   ! mycall
           apmask(116:143)=1  ! hiscall
           apmask(144:159)=1  ! RRR or 73 or RR73
           llrap=llr
           llrap(88:143)=apmag*apsym(1:56)/ss
           if(iaptype.eq.4) llrap(144:159)=apmag*mrrr/ss 
           if(iaptype.eq.5) llrap(144:159)=apmag*m73/ss 
           if(iaptype.eq.6) llrap(144:159)=apmag*mrr73/ss 
        endif
        if(iaptype.eq.7) then   ! ???, dxcall, ???
           apmask=0
           apmask(116:143)=1  ! hiscall
           apmask(144)=1      ! not free text
           llrap=llr
           llrap(115)=llra(115)
           llrap(116:143)=apmag*apsym(29:56)/ss
           llrap(144)=-apmag/ss
        endif
     endif

     cw=0
     call timer('bpd174  ',0)
     call bpdecode174(llrap,apmask,max_iterations,decoded,cw,nharderrors,  &
          niterations)
     call timer('bpd174  ',1)
     dmin=0.0
     if(ndepth.eq.3 .and. nharderrors.lt.0) then
        ndeep=3
        if(abs(nfqso-f1).le.napwid .or. abs(nftx-f1).le.napwid) then
          if((ipass.eq.2 .or. ipass.eq.3) .and. .not.nagain) then
            ndeep=3 
          else   
            ndeep=4  
          endif
        endif
        if(nagain) ndeep=5
        call timer('osd174  ',0)
        call osd174(llrap,apmask,ndeep,decoded,cw,nharderrors,dmin)
        call timer('osd174  ',1)
     endif
     nbadcrc=1
     message='                      '
     xsnr=-99.0
     if(count(cw.eq.0).eq.174) cycle           !Reject the all-zero codeword
     if(any(decoded(73:75).ne.0)) cycle        !Reject if any of the 3 extra bits are nonzero
     if(nharderrors.ge.0 .and. nharderrors+dmin.lt.60.0 .and. &        
        .not.(sync.lt.2.0 .and. nharderrors.gt.35)      .and. &
        .not.(ipass.gt.1 .and. nharderrors.gt.39)       .and. &
        .not.(ipass.eq.3 .and. nharderrors.gt.30)             &
       ) then
        call chkcrc12a(decoded,nbadcrc)
     else
        nharderrors=-1
        cycle 
     endif
     if(nbadcrc.eq.0) then
        call extractmessage174(decoded,message,ncrcflag,recent_calls,nrecent)
        call genft8(message,mygrid6,bcontest,msgsent,msgbits,itone)
        if(lsubtract) call subtractft8(dd0,itone,f1,xdt2)
        xsig=0.0
        xnoi=0.0
        do i=1,79
           xsig=xsig+s2(itone(i),i)**2
           ios=mod(itone(i)+4,7)
           xnoi=xnoi+s2(ios,i)**2
        enddo
        xsnr=0.001
        if(xnoi.gt.0 .and. xnoi.lt.xsig) xsnr=xsig/xnoi-1.0
        xsnr=10.0*log10(xsnr)-27.0
!###
        xsnr2=db(xsig/xbase - 1.0) - 32.0
!        write(52,3052) f1,xdt,xsig,xnoi,xbase,xsnr,xsnr2
!3052    format(7f10.2)
        xsnr=xsnr2
!###
        if(xsnr .lt. -24.0) xsnr=-24.0
        return
     endif
  enddo
 
  return
end subroutine ft8b

subroutine normalizebmet(bmet,n)
  real bmet(n)

  bmetav=sum(bmet)/real(n)
  bmet2av=sum(bmet*bmet)/real(n)
  var=bmet2av-bmetav*bmetav
  if( var .gt. 0.0 ) then
     bmetsig=sqrt(var)
  else
     bmetsig=sqrt(bmet2av)
  endif
  bmet=bmet/bmetsig
  return
end subroutine normalizebmet
