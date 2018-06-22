subroutine ft8b_2(dd0,newdat,nQSOProgress,nfqso,nftx,ndepth,lapon,lapcqonly,   &
     napwid,lsubtract,nagain,iaptype,mycall12,mygrid6,hiscall12,bcontest,    &
     sync0,f1,xdt,xbase,apsym,nharderrors,dmin,nbadcrc,ipass,iera,msg37,xsnr)  

  use crc
  use timer_module, only: timer
  include 'ft8_params.f90'
  parameter(NP2=2812)
  character*37 msg37
  character message*22,msgsent*22
  character*12 mycall12,hiscall12
  character*6 mycall6,mygrid6,hiscall6,c1,c2
  character*87 cbits
  logical bcontest
  real a(5)
  real s8d(0:7,ND),s8(0:7,NN),s8dsort(8*ND)
  real s64(0:7,0:7)
  real ps(0:63),psl(0:63)
  real bmeta(3*ND),bmetb(3*ND),bmetc(3*ND),bmetap(3*ND)
  real llra(3*ND),llrb(3*ND),llrc(3*ND),llrd(3*ND)           !Soft symbols
  real dd0(15*12000)
  integer*1 message77(77),apmask(3*ND),cw(3*ND)
  integer*1 msgbits(77)
  integer apsym(77)
  integer mcq(28),mde(28),mrrr(16),m73(16),mrr73(16)
  integer itone(NN)
  integer indxs8d(8*ND)
  integer icos7(0:6),ip(1)
  integer nappasses(0:5)  !Number of decoding passes to use for each QSO state
  integer naptypes(0:5,4) ! (nQSOProgress, decoding pass)  maximum of 4 passes for now
  integer*1, target:: i1hiscall(12)
  integer invgraymap(0:7)
  complex cd0(3200)
  complex ctwk(32)
  complex csymb(32)
  complex cs(0:7,NN)
  logical first,newdat,lsubtract,lapon,lapcqonly,nagain
  equivalence (s8d,s8dsort)
  data icos7/3,1,4,0,6,5,2/  ! Flipped w.r.t. original FT8 sync array
  data mcq/1,1,1,1,1,0,1,0,0,0,0,0,1,0,0,0,0,0,1,1,0,0,0,1,1,0,0,1/
  data mrrr/0,1,1,1,1,1,1,0,1,1,0,0,1,1,1,1/
  data m73/0,1,1,1,1,1,1,0,1,1,0,1,0,0,0,0/
  data mde/1,1,1,1,1,1,1,1,0,1,1,0,0,1,0,0,0,0,0,1,1,1,0,1,0,0,0,1/
  data mrr73/0,0,0,0,0,0,1,0,0,0,0,1,0,1,0,1/
  data first/.true./
  data invgraymap/0,1,3,2,6,7,5,4/

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
     naptypes(5,1:4)=(/3,1,2,0/)  
     first=.false.
  endif

  max_iterations=30
  nharderrors=-1
  nbadcrc=1  ! this is used upstream to flag good decodes. 
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
     call sync8d(cd0,idt,ctwk,0,2,sync)
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
   call sync8d(cd0,i0,ctwk,1,2,sync)
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

  call sync8d(cd0,i0,ctwk,2,2,sync)

  do k=1,NN
    i1=ibest+(k-1)*32
    csymb=cmplx(0.0,0.0)
    if( i1.ge.1 .and. i1+31 .le. NP2 ) csymb=cd0(i1:i1+31)
    call four2a(csymb,32,1,-1,1)
    cs(0:7,k)=csymb(1:8)
    s8(0:7,k)=abs(csymb(1:8))/1e3
  enddo  
  

! sync quality check
  is1=0
  is2=0
  is3=0
  do k=1,7
    ip=maxloc(s8(:,k))
    if(icos7(k-1).eq.(ip(1)-1)) is1=is1+1
    ip=maxloc(s8(:,k+36))
    if(icos7(k-1).eq.(ip(1)-1)) is2=is2+1
    ip=maxloc(s8(:,k+72))
    if(icos7(k-1).eq.(ip(1)-1)) is3=is3+1
  enddo
! hard sync sum - max is 21
  nsync=is1+is2+is3
  if(nsync .le. 6) then ! bail out
    nbadcrc=1
!write(*,*) 'failed sync sanity test'
    return
  endif

  j=0
  do k=1,NN
     if(k.le.7) cycle
     if(k.ge.37 .and. k.le.43) cycle
     if(k.gt.72) cycle
     j=j+1
     s8d(0:7,j)=s8(0:7,k)
  enddo  

  call indexx(s8dsort,8*ND,indxs8d)
  xmeds8d=s8dsort(indxs8d(nint(0.5*8*ND)))
  s8d=s8d/xmeds8d

  do j=1,ND
     i4=3*j-2
     i2=3*j-1
     i1=3*j
! Max amplitude
     ps(0:7)=s8d(0:7,j)
! For Gray bit-to-symbol mapping
     r1=max(ps(1),ps(2),ps(5),ps(6))-max(ps(0),ps(3),ps(4),ps(7))
     r2=max(ps(2),ps(3),ps(4),ps(5))-max(ps(0),ps(1),ps(6),ps(7))
     r4=max(ps(4),ps(5),ps(6),ps(7))-max(ps(0),ps(1),ps(2),ps(3))
     bmeta(i4)=r4
     bmeta(i2)=r2
     bmeta(i1)=r1
! Max log metric
     psl=log(ps+1e-32)
! Gray bit-to-symbol mapping
     r1=max(psl(1),psl(2),psl(5),psl(6))-max(psl(0),psl(3),psl(4),ps(7))
     r2=max(psl(2),psl(3),psl(4),psl(5))-max(psl(0),psl(1),psl(6),ps(7))
     r4=max(psl(4),psl(5),psl(6),psl(7))-max(psl(0),psl(1),psl(2),ps(3))
     bmetb(i4)=r4
     bmetb(i2)=r2
     bmetb(i1)=r1
  enddo

! Do 2-symbol detection
  do ihalf=1,2
    do k=1,29,2
      if(ihalf.eq.1) ks=k+7
      if(ihalf.eq.2) ks=k+43
      amax=-1.0
      do i=0,63
        il=i/8
        ir=iand(i,7)
        s64(il,ir)=abs(cs(il,ks)+cs(ir,ks+1))
        if(s64(il,ir).gt.amax) then
          ilb=il
          irb=ir
          amax=s64(il,ir)
        endif
      enddo
!write(*,*) k,ilb,irb,amax
      maxa0=maxval(s64(0:7,0))
      maxa1=maxval(s64(0:7,1))
      maxa2=maxval(s64(0:7,2))
      maxa3=maxval(s64(0:7,3))
      maxa4=maxval(s64(0:7,4))
      maxa5=maxval(s64(0:7,5))
      maxa6=maxval(s64(0:7,6))
      maxa7=maxval(s64(0:7,7))
      max0a=maxval(s64(0,0:7))
      max1a=maxval(s64(1,0:7))
      max2a=maxval(s64(2,0:7))
      max3a=maxval(s64(3,0:7))
      max4a=maxval(s64(4,0:7))
      max5a=maxval(s64(5,0:7))
      max6a=maxval(s64(6,0:7))
      max7a=maxval(s64(7,0:7))
      r1=max(maxa1,maxa2,maxa5,maxa6) - &
         max(maxa0,maxa3,maxa4,maxa7) 
      r2=max(maxa2,maxa3,maxa4,maxa5) - &
         max(maxa0,maxa1,maxa6,maxa7) 
      r4=max(maxa4,maxa5,maxa6,maxa7) - &
         max(maxa0,maxa1,maxa2,maxa3) 
      r8=max(max1a,max2a,max5a,max6a) - &
         max(max0a,max3a,max4a,max7a) 
      r16=max(max2a,max3a,max4a,max5a) - &
         max(max0a,max1a,max6a,max7a) 
      r32=max(max4a,max5a,max6a,max7a) - &
         max(max0a,max1a,max2a,max3a) 
      i32=1+(k-1)*3+(ihalf-1)*87
      bmetc(i32)=r32
      bmetc(i32+1)=r16
      bmetc(i32+2)=r8
      if(k.lt.29) then
         bmetc(i32+3)=r4
         bmetc(i32+4)=r2
         bmetc(i32+5)=r1
      endif
    enddo
  enddo

  call normalizebmet(bmeta,3*ND)
  call normalizebmet(bmetb,3*ND)
  call normalizebmet(bmetc,3*ND)
  bmetap=bmeta

!do i=1,174
!write(*,*) i,bmeta(i),bmetc(i)
!enddo

  scalefac=2.83
  llra=scalefac*bmeta
  llrb=scalefac*bmetb
  llrc=scalefac*bmetc
  apmag=scalefac*(maxval(abs(bmetap))*1.01)

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
     if(.not.lapcqonly) then
        npasses=4+nappasses(nQSOProgress)
     else
        npasses=5 
     endif
  else
     npasses=4
  endif

  do ipass=1,npasses 
!  do ipass=1,2 
     llrd=llra
     if(ipass.eq.2) llrd=llrb
!     if(ipass.eq.3) llrd(1:24)=0. 
     if(ipass.eq.3) llrd=llrc
     if(ipass.eq.4) llrd(1:48)=0. 
     if(ipass.le.4) then
        apmask=0
        iaptype=0
     endif
        
     if(ipass .gt. 4) then
        if(.not.lapcqonly) then
           iaptype=naptypes(nQSOProgress,ipass-4)
        else
           iaptype=1
        endif
        if(iaptype.ge.3 .and. (abs(f1-nfqso).gt.napwid .and. abs(f1-nftx).gt.napwid) ) cycle 
        if(iaptype.eq.1 .or. iaptype.eq.2 ) then ! AP,???,??? 
           apmask=0
           apmask(1:27)=1    ! first 27 bits (9 tones) are AP
           if(iaptype.eq.1) llrd(1:27)=apmag*mcq(1:27)
           if(iaptype.eq.2) llrd(1:27)=apmag*apsym(1:27)
        endif
        if(iaptype.eq.3) then   ! mycall, dxcall, ???
           apmask=0
           apmask(1:54)=1   
           llrd(1:54)=apmag*apsym(1:54)
        endif
        if(iaptype.eq.4 .or. iaptype.eq.5 .or. iaptype.eq.6) then  
           apmask=0
           apmask(1:72)=1   ! mycall, hiscall, RRR|73|RR73
           llrd(1:56)=apmag*apsym(1:56)
           if(iaptype.eq.4) llrd(57:72)=apmag*mrrr 
           if(iaptype.eq.5) llrd(57:72)=apmag*m73 
           if(iaptype.eq.6) llrd(57:72)=apmag*mrr73 
        endif
        if(iaptype.eq.7) then   ! ???, dxcall, ???
           apmask=0
           apmask(31:54)=1  ! hiscall
           llrd(31:54)=apmag*apsym(31:54)
        endif
     endif

     cw=0
     call timer('bpd174_91 ',0)
     call bpdecode174_91(llrd,apmask,max_iterations,message77,cw,nharderrors,  &
          niterations)
     call timer('bpd174_91 ',1)
     dmin=0.0
     if(ndepth.eq.3 .and. nharderrors.lt.0) then
        ndeep=3
        if(abs(nfqso-f1).le.napwid .or. abs(nftx-f1).le.napwid) then
          if((ipass.eq.3 .or. ipass.eq.4) .and. .not.nagain) then
            ndeep=3 
          else   
            ndeep=4  
          endif
        endif
        if(nagain) ndeep=5
        call timer('osd174_91 ',0)
        call osd174_91(llrd,apmask,ndeep,message77,cw,nharderrors,dmin)
        call timer('osd174_91 ',1)
     endif
     message='                      '
     xsnr=-99.0
     if(nharderrors.lt.0) cycle
     if(count(cw.eq.0).eq.174) cycle           !Reject the all-zero codeword
     nbadcrc=0  ! If we get this far, must be a valid codeword.
     i5bit=16*message77(73) + 8*message77(74) + 4*message77(75) + 2*message77(76) + message77(77)
     iFreeText=message77(57)
     if(i5bit.eq.1) message77(57:)=0
     call extractmessage77(message77,message)
! This needs fixing for messages with i5bit=1        
     call genft8_174_91(message,mygrid6,bcontest,i5bit,msgsent,msgbits,itone)
     if(lsubtract) call subtractft8(dd0,itone,f1,xdt2)
     xsig=0.0
     xnoi=0.0
     do i=1,79
        xsig=xsig+s8(itone(i),i)**2
        ios=mod(itone(i)+4,7)
        xnoi=xnoi+s8(ios,i)**2
     enddo
     xsnr=0.001
     if(xnoi.gt.0 .and. xnoi.lt.xsig) xsnr=xsig/xnoi-1.0
     xsnr=10.0*log10(xsnr)-27.0
     xsnr2=db(xsig/xbase - 1.0) - 32.0
     if(.not.nagain) xsnr=xsnr2
     if(xsnr .lt. -24.0) xsnr=-24.0
     
     if(i5bit.eq.1) then
        do i=1,12
           i1hiscall(i)=ichar(hiscall12(i:i))
        enddo
        icrc10=crc10(c_loc(i1hiscall),12)
        write(cbits,1001) decoded
1001    format(87i1)
        read(cbits,1002) ncrc10,nrpt
1002    format(56x,b10,b6)
        irpt=nrpt-30
        i1=index(message,' ')
        i2=index(message(i1+1:),' ') + i1
        c1=message(1:i1)//'   '
        c2=message(i1+1:i2)//'   '

        if(ncrc10.eq.icrc10) msg37=c1//' RR73; '//c2//' <'//      &
             trim(hiscall12)//'>    '
        if(ncrc10.ne.icrc10) msg37=c1//' RR73; '//c2//' <...>    '
           
        msg37=c1//' RR73; '//c2//' <...>    '
        write(msg37(35:37),1010) irpt
1010    format(i3.2)
        if(msg37(35:35).ne.'-') msg37(35:35)='+'
           
        iz=len(trim(msg37))
        do iter=1,10                           !Collapse multiple blanks
           ib2=index(msg37(1:iz),'  ')
           if(ib2.lt.1) exit
           msg37=msg37(1:ib2)//msg37(ib2+2:)
           iz=iz-1
        enddo
     else
        msg37=message//'               '
     endif
     return
  enddo
  return
end subroutine ft8b_2

! This currently resides in ft8b_1.f90
!subroutine normalizebmet(bmet,n)
!  real bmet(n)
!
!  bmetav=sum(bmet)/real(n)
!  bmet2av=sum(bmet*bmet)/real(n)
!  var=bmet2av-bmetav*bmetav
!  if( var .gt. 0.0 ) then
!     bmetsig=sqrt(var)
!  else
!     bmetsig=sqrt(bmet2av)
!  endif
!  bmet=bmet/bmetsig
!  return
!end subroutine normalizebmet


