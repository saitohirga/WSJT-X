subroutine syncmsk(cdat,npts,jpk,ipk,idf,rmax,snr,metric,decoded)

! Attempt synchronization, and if successful decode using Viterbi algorithm.

  use iso_c_binding, only: c_loc,c_size_t
  use packjt
  use hashing
  use timer_module, only: timer

  parameter (NSPM=1404,NSAVE=2000)
  complex cdat(npts)                    !Analytic signal
  complex cb(66)                        !Complex waveform for Barker-11 code
  complex cd(0:11,0:3)
  complex c(0:NSPM-1)                   !Complex data for one message length
  complex c2(0:NSPM-1)
  complex cb3(1:NSPM,3)
  real r(12000)
  real rdat(12000)
  real ss1(12000)
  real symbol(234)
  real rdata(198)
  real rd2(198)
  real rsave(NSAVE)
  real xp(29)
  complex z,z0,z1,z2,z3,cfac
  integer*1 e1(198)
  integer*1, target :: d8(13)
  integer*1 i1hash(4)
  integer*1 i1
  integer*4 i4Msg6BitWords(12)            !72-bit message as 6-bit words
  integer mettab(0:255,0:1)               !Metric table for BPSK modulation
  integer ipksave(NSAVE)
  integer jpksave(NSAVE)
  integer indx(NSAVE)
  integer b11(11)                      !Barker-11 code
  character*22 decoded
  character*72 c72
  logical first
  equivalence (i1,i4)
  equivalence (ihash,i1hash)
  data xp/0.500000, 0.401241, 0.309897, 0.231832, 0.168095,    &
          0.119704, 0.083523, 0.057387, 0.039215, 0.026890,    &
          0.018084, 0.012184, 0.008196, 0.005475, 0.003808,    &
          0.002481, 0.001710, 0.001052, 0.000789, 0.000469,    &
          0.000329, 0.000225, 0.000187, 0.000086, 0.000063,    &
          0.000017, 0.000091, 0.000032, 0.000045/
  data first/.true./
  data b11/1,1,1,0,0,0,1,0,0,1,0/
  save first,cb,cd,twopi,dt,f0,f1,mettab

  phi=0.
  if(first) then
! Get the metric table
     bias=0.0
     scale=20.0
     xln2=log(2.0)
     mettab=0
     do i=128,156
        x0=log(max(0.001,2.0*xp(i-127)))/xln2
        x1=log(max(0.001,2.0*(1.0-xp(i-127))))/xln2
        mettab(i,0)=nint(scale*(x0-bias))
        mettab(i,1)=nint(scale*(x1-bias))
        mettab(256-i,0)=mettab(i,1)
        mettab(256-i,1)=mettab(i,0)
     enddo
     do i=157,255
        mettab(i,0)=mettab(156,0)
        mettab(i,1)=mettab(156,1)
        mettab(256-i,0)=mettab(i,1)
        mettab(256-i,1)=mettab(i,0)
     enddo
     j=0
     twopi=8.0*atan(1.0)
     dt=1.0/12000.0
     f0=1000.0
     f1=2000.0
     dphi=0
     do i=1,11
        if(b11(i).eq.0) dphi=twopi*f0*dt
        if(b11(i).eq.1) dphi=twopi*f1*dt
        do n=1,6
           j=j+1
           phi=phi+dphi
           cb(j)=cmplx(cos(phi),sin(phi))
        enddo
     enddo
     cb3=0.
     cb3(1:66,1)=cb
     cb3(283:348,1)=cb
     cb3(769:834,1)=cb

     cb3(1:66,2)=cb
     cb3(487:552,2)=cb
     cb3(1123:1188,2)=cb

     cb3(1:66,3)=cb
     cb3(637:702,3)=cb
     cb3(919:984,3)=cb

     phi=0.
     do n=0,3
        k=-1
        dphi=twopi*f0*dt
        if(n.ge.2) dphi=twopi*f1*dt
        do i=0,5
           k=k+1
           phi=phi+dphi
           if(phi.gt.twopi) phi=phi-twopi
           cd(k,n)=cmplx(cos(phi),sin(phi))
        enddo

        dphi=twopi*f0*dt
        if(mod(n,2).eq.1) dphi=twopi*f1*dt
        do i=6,11
           k=k+1
           phi=phi+dphi
           if(phi.gt.twopi) phi=phi-twopi
           cd(k,n)=cmplx(cos(phi),sin(phi))
        enddo
     enddo

     first=.false.
  endif

  nfft=NSPM
  jz=npts-nfft
  decoded="                      "
  ipk=0
  jpk=0
  metric=-9999
  r=0.

  call timer('sync1   ',0)
  do j=1,jz                               !Find the Barker-11 sync vectors
     z=0.
     ss=0.
     do i=1,66
        ss=ss + real(cdat(j+i-1))**2 + aimag(cdat(j+i-1))**2
        z=z + cdat(j+i-1)*conjg(cb(i))    !Signal matching Barker 11
     enddo
     ss=sqrt(ss/66.0)*66.0
     r(j)=abs(z)/(0.908*ss)               !Goodness-of-fit to Barker 11
     ss1(j)=ss
  enddo
  call timer('sync1   ',1)

  call timer('sync2   ',0)
  jz=npts-nfft
  rmax=0.
!  n1=35, n2=69, n3=94
  k=0
  do j=1,jz                               !Find best full-message sync
     if(ss1(j).lt.85.0) cycle
     r1=r(j) + r(j+282) + r(j+768)        ! 6*(12+n1) 6*(24+n1+n2)
     r2=r(j) + r(j+486) + r(j+1122)       ! 6*(12+n2) 6*(24+n2+n3)
     r3=r(j) + r(j+636) + r(j+918)        ! 6*(12+n3) 6*(24+n3+n1)
     if(r1.gt.rmax) then
        rmax=r1
        jpk=j
        ipk=1
     endif
     if(r2.gt.rmax) then
        rmax=r2
        jpk=j
        ipk=2
     endif
     if(r3.gt.rmax) then
        rmax=r3
        jpk=j
        ipk=3
     endif
     rrmax=max(r1,r2,r3)
     if(rrmax.gt.1.9) then
        k=min(k+1,NSAVE)
        if(r1.eq.rrmax) ipksave(k)=1
        if(r2.eq.rrmax) ipksave(k)=2
        if(r3.eq.rrmax) ipksave(k)=3
        jpksave(k)=j
        rsave(k)=rrmax
     endif
  enddo
  call timer('sync2   ',1)
  kmax=k

  call indexx(rsave,kmax,indx)

  call timer('sync3   ',0)
  do kk=1,kmax
     k=indx(kmax+1-kk)
     ipk=ipksave(k)
     jpk=jpksave(k)
     rmax=rsave(k)

     c=conjg(cb3(1:NSPM,ipk))*cdat(jpk:jpk+nfft-1)
     smax=0.
     dfx=0.
     idfbest=0
     do itry=1,25
        idf=itry/2
        if(mod(itry,2).eq.0) idf=-idf
        idf=4*idf
        twk=idf
        call tweak1(c,NSPM,-twk,c2)
        z=sum(c2)
        if(abs(z).gt.smax) then
           dfx=twk
           smax=abs(z)
           phi=atan2(aimag(z),real(z))            !Carrier phase offset
           idfbest=idf
        endif
     enddo
     idf=idfbest
     call tweak1(cdat,npts,-dfx,cdat)
     cfac=cmplx(cos(phi),-sin(phi))
     cdat=cfac*cdat

     sig=0.
     ref=0.
     rdat(1:npts)=cdat
     iz=11
     do k=1,234                                !Compute soft symbols
        j=jpk+6*(k-1)

        z0=2.0*dot_product(cdat(j:j+iz),cd(0:iz,0))
        z1=2.0*dot_product(cdat(j:j+iz),cd(0:iz,1))
        z2=2.0*dot_product(cdat(j:j+iz),cd(0:iz,2))
        z3=2.0*dot_product(cdat(j:j+iz),cd(0:iz,3))

!### Maybe these should be weighted by yellow() ?
        if(j+1404+iz.lt.npts) then
           z0=z0 + dot_product(cdat(j+1404:j+1404+iz),cd(0:iz,0))
           z1=z1 + dot_product(cdat(j+1404:j+1404+iz),cd(0:iz,1))
           z2=z2 + dot_product(cdat(j+1404:j+1404+iz),cd(0:iz,2))
           z3=z3 + dot_product(cdat(j+1404:j+1404+iz),cd(0:iz,3))
        endif

        if(j-1404.ge.1) then
           z0=z0 + dot_product(cdat(j-1404:j-1404+iz),cd(0:iz,0))
           z1=z1 + dot_product(cdat(j-1404:j-1404+iz),cd(0:iz,1))
           z2=z2 + dot_product(cdat(j-1404:j-1404+iz),cd(0:iz,2))
           z3=z3 + dot_product(cdat(j-1404:j-1404+iz),cd(0:iz,3))
        endif

        sym=max(abs(real(z2)),abs(real(z3))) - max(abs(real(z0)),abs(real(z1)))

        if(sym.lt.0.0) then
           phi=atan2(aimag(z0),real(z0))
           sig=sig + real(z0)**2
           ref=ref + aimag(z0)**2
        else
           phi=atan2(aimag(z1),real(z1))
           sig=sig + real(z1)**2
           ref=ref + aimag(z1)**2
        endif
        n=k
        if(ipk.eq.2) n=k+47
        if(ipk.eq.3) n=k+128
        if(n.gt.234) n=n-234
        ibit=0
        if(sym.ge.0) ibit=1
        symbol(n)=sym
     enddo
     snr=db(sig/ref-1.0)

     rdata(1:35)=symbol(12:46)
     rdata(36:104)=symbol(59:127)
     rdata(105:198)=symbol(140:233)

! Re-order the symbols and make them i*1
     j=0
     do i=1,99
        i4=128+rdata(i)                       !### Should be nint() ??? ###
        if(i4.gt.255)  i4=255
        if(i4.lt.0) i4=0
        j=j+1
        e1(j)=i1
        rd2(j)=rdata(i)
        i4=128+rdata(i+99)
        if(i4.gt.255)  i4=255
        if(i4.lt.0) i4=0
        j=j+1
        e1(j)=i1
        rd2(j)=rdata(i+99)
     enddo

! Decode the message
     nb1=87
     call vit213(e1,nb1,mettab,d8,metric)
     ihash=nhash(c_loc(d8),int(9,c_size_t),146)
     ihash=2*iand(ihash,32767)
     decoded='                      '
     if(d8(10).eq.i1hash(2) .and. d8(11).eq.i1hash(1)) then
        write(c72,1012) d8(1:9)
1012    format(9b8.8)
        read(c72,1014) i4Msg6BitWords
1014    format(12b6.6)
        call unpackmsg(i4Msg6BitWords,decoded) !Unpack to get msgsent
     endif
     if(decoded.ne.'                      ') exit
  enddo
  call timer('sync3   ',1)

  return
end subroutine syncmsk
