subroutine ft8b_2(dd0,newdat,nQSOProgress,nfqso,nftx,ndepth,lapon,lapcqonly,  &
     napwid,lsubtract,nagain,iaptype,mycall12,hiscall12,                      &
     sync0,f1,xdt,xbase,apsym,nharderrors,dmin,nbadcrc,ipass,iera,msg37,xsnr)  

  use crc
  use timer_module, only: timer
  use packjt77
  include 'ft8_params.f90'
  parameter(NP2=2812)
  character*37 msg37,msgsent37
  character*12 mycall12,hiscall12
  character*77 c77
  character*6 mycall6,hiscall6,c1,c2
  character*87 cbits
  real a(5)
  real s8(0:7,NN)
  real s2(0:511),s2l(0:511)
  real bmeta(3*ND),bmetb(3*ND),bmetc(3*ND)
  real bmetal(3*ND),bmetbl(3*ND),bmetcl(3*ND)
  real llra(3*ND),llrb(3*ND),llrc(3*ND),llrd(3*ND)           !Soft symbols
  real llral(3*ND),llrbl(3*ND),llrcl(3*ND)                   !Soft symbols
  real dd0(15*12000)
  integer*1 message77(77),apmask(3*ND),cw(3*ND)
  integer*1 msgbits(77)
  integer apsym(77)
  integer mcq(29),mrrr(19),m73(19),mrr73(19)
  integer itone(NN)
  integer icos7(0:6),ip(1)
  integer nappasses(0:5)  !Number of decoding passes to use for each QSO state
  integer naptypes(0:5,4) ! (nQSOProgress, decoding pass)  maximum of 4 passes for now
  integer*1, target:: i1hiscall(12)
  logical one(0:511,0:8)
  integer graymap(0:7)
  complex cd0(0:3199)
  complex ctwk(32)
  complex csymb(32)
  complex cs(0:7,NN)
  logical first,newdat,lsubtract,lapon,lapcqonly,nagain
  data icos7/3,1,4,0,6,5,2/  ! Flipped w.r.t. original FT8 sync array
  data   mcq/0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0/
  data  mrrr/0,1,1,1,1,1,1,0,1,0,0,1,0,0,1,0,0,0,1/
  data   m73/0,1,1,1,1,1,1,0,1,0,0,1,0,1,0,0,0,0,1/
  data mrr73/0,1,1,1,1,1,1,0,0,1,1,1,0,1,0,1,0,0,1/
  data first/.true./
  data graymap/0,1,3,2,5,6,4,7/
  save nappasses,naptypes,one

  if(first) then
     mcq=2*mcq-1
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
!   1        CQ     ???    ???           (29+3=32 ap bits)
!   2        MyCall ???    ???           (29+3=32 ap bits)
!   3        MyCall DxCall ???           (58+3=61 ap bits)
!   4        MyCall DxCall RRR           (77 ap bits)
!   5        MyCall DxCall 73            (77 ap bits)
!   6        MyCall DxCall RR73          (77 ap bits)

     naptypes(0,1:4)=(/1,2,0,0/)
     naptypes(1,1:4)=(/2,3,0,0/)
     naptypes(2,1:4)=(/2,3,0,0/)
     naptypes(3,1:4)=(/3,4,5,6/)
     naptypes(4,1:4)=(/3,4,5,6/)
     naptypes(5,1:4)=(/3,1,2,0/)  

     one=.false.
     do i=0,511
       do j=0,8
         if(iand(i,2**j).ne.0) one(i,j)=.true.
       enddo
     enddo
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
  call sync8d(cd0,i0,ctwk,0,2,sync)

  do k=1,NN
    i1=ibest+(k-1)*32
    csymb=cmplx(0.0,0.0)
    if( i1.ge.0 .and. i1+31 .le. NP2-1 ) csymb=cd0(i1:i1+31)
    call four2a(csymb,32,1,-1,1)
    cs(0:7,k)=csymb(1:8)/1e3
    s8(0:7,k)=abs(csymb(1:8))
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
    return
  endif

  do nsym=1,3
    nt=2**(3*nsym)
    do ihalf=1,2
      do k=1,29,nsym
        if(ihalf.eq.1) ks=k+7
        if(ihalf.eq.2) ks=k+43
        amax=-1.0
        do i=0,nt-1
          i1=i/64
          i2=iand(i,63)/8
          i3=iand(i,7)
          if(nsym.eq.1) then
            s2(i)=abs(cs(graymap(i3),ks))
          elseif(nsym.eq.2) then
            s2(i)=abs(cs(graymap(i2),ks)+cs(graymap(i3),ks+1))
          elseif(nsym.eq.3) then
            s2(i)=abs(cs(graymap(i1),ks)+cs(graymap(i2),ks+1)+cs(graymap(i3),ks+2))
          else
            print*,"Error - nsym must be 1, 2, or 3."
          endif
        enddo
        s2l(0:nt-1)=log(s2(0:nt-1)+1e-32)
        i32=1+(k-1)*3+(ihalf-1)*87
        if(nsym.eq.1) ibmax=2 
        if(nsym.eq.2) ibmax=5 
        if(nsym.eq.3) ibmax=8 
        do ib=0,ibmax
          bm=maxval(s2(0:nt-1),one(0:nt-1,ibmax-ib)) - &
             maxval(s2(0:nt-1),.not.one(0:nt-1,ibmax-ib))
!          bml=maxval(s2l(0:nt-1),one(0:nt-1,ibmax-ib)) - &
!              maxval(s2l(0:nt-1),.not.one(0:nt-1,ibmax-ib))
          if(i32+ib .gt.174) cycle
          if(nsym.eq.1) then
            bmeta(i32+ib)=bm
!            bmetal(i32+ib)=bml
          elseif(nsym.eq.2) then
            bmetb(i32+ib)=bm
!            bmetbl(i32+ib)=bml
          elseif(nsym.eq.3) then
            bmetc(i32+ib)=bm
!            bmetcl(i32+ib)=bml
          endif
        enddo
      enddo
    enddo
  enddo
  call normalizebmet(bmeta,3*ND)
!  call normalizebmet(bmetal,3*ND)
  call normalizebmet(bmetb,3*ND)
!  call normalizebmet(bmetbl,3*ND)
  call normalizebmet(bmetc,3*ND)
!  call normalizebmet(bmetcl,3*ND)

  scalefac=2.83
  llra=scalefac*bmeta
!  llral=scalefac*bmetal
  llrb=scalefac*bmetb
!  llrbl=scalefac*bmetbl
  llrc=scalefac*bmetc
!  llrcl=scalefac*bmetcl

  apmag=maxval(abs(llrb))*1.01

! pass #
!------------------------------
!   1        regular decoding, nsym=1 
!   2        regular decoding, nsym=2 
!   3        regular decoding, nsym=3 
!   4        ap pass 1, nsym=1 (for now?)
!   5        ap pass 2
!   6        ap pass 3
!   7        ap pass 4

  if(lapon) then 
     if(.not.lapcqonly) then
        npasses=3+nappasses(nQSOProgress)
     else
        npasses=4 
     endif
  else
     npasses=3
  endif

  do ipass=1,npasses 
     llrd=llra
     if(ipass.eq.2) llrd=llrb
     if(ipass.eq.3) llrd=llrc
     if(ipass.le.3) then
        apmask=0
        iaptype=0
     endif

     if(ipass .gt. 3) then
        llrd=llra
        if(.not.lapcqonly) then
           iaptype=naptypes(nQSOProgress,ipass-3)
        else
           iaptype=1
        endif
        if(iaptype.ge.3 .and. (abs(f1-nfqso).gt.napwid .and. abs(f1-nftx).gt.napwid) ) cycle 
        if(iaptype.eq.1 .or. iaptype.eq.2 ) then ! AP,???,??? 
           apmask=0
           apmask(1:29)=1  
           apmask(75:77)=1 
           llrd(75:77)=apmag*apsym(75:77)
           if(iaptype.eq.1) llrd(1:29)=apmag*mcq(1:29)
           if(iaptype.eq.2) llrd(1:29)=apmag*apsym(1:29)
        endif
        if(iaptype.eq.3) then   ! mycall, dxcall, ???
           apmask=0
           apmask(1:56)=1   
           apmask(75:77)=1 
           llrd(1:56)=apmag*apsym(1:56)
           llrd(75:77)=apmag*apsym(75:77)
        endif
        if(iaptype.eq.4 .or. iaptype.eq.5 .or. iaptype.eq.6) then  
           apmask=0
           apmask(1:77)=1   ! mycall, hiscall, RRR|73|RR73
           llrd(1:58)=apmag*apsym(1:58)
           if(iaptype.eq.4) llrd(59:77)=apmag*mrrr 
           if(iaptype.eq.5) llrd(59:77)=apmag*m73 
           if(iaptype.eq.6) llrd(59:77)=apmag*mrr73 
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

     msg37='                                     '
     xsnr=-99.0
     if(nharderrors.lt.0 .or. nharderrors.gt.36) cycle
     if(count(cw.eq.0).eq.174) cycle           !Reject the all-zero codeword
     write(c77,'(77i1)') message77
     read(c77(72:74),'(b3)') n3
     read(c77(75:77),'(b3)') i3
     if(i3.gt.4 .or. (i3.eq.0.and.n3.gt.5)) then
        cycle
     endif
     call unpack77(c77,msg37)
     if(index(msg37,'QU1RK').gt.0) then
        cycle
     endif
     nbadcrc=0  ! If we get this far: valid codeword, valid (i3,n3), nonquirky message.
     call genft8_174_91(msg37,i3,n3,msgsent37,msgbits,itone)
     if(lsubtract) call subtractft8(dd0,itone,f1,xdt) 
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
! need to reconcile signal normalization between this routine and the old ft8b_1 so 
! that SNRs come out the same.
     xsnr2=db(xsig/xbase - 1.0) - 32.0
!     if(.not.nagain) xsnr=xsnr2
     if(xsnr .lt. -24.0) xsnr=-24.0
     
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


