subroutine timf2x(k,nfft,ntrperiod,nwindow,nb,peaklimit,faclim,cx0,cx1,    &
     slimit,lstrong,px,nzap)

! Sequential processing of time-domain I/Q data, using Linrad-like
! "first FFT" and "first backward FFT".  

!  cx0       - complex input data
!  nfft      - length of FFTs
!  nwindow   - 0 for no window, 2 for sin^2 window
!  cx1       - output data

! Non-windowed processing means no overlap, so kstep=nfft.  
! Sin^2 window has 50% overlap, kstep=nfft/2.

! Frequencies with strong signals are identified and separated.  Back
! transforms are done separately for weak and strong signals, so that
! noise blanking can be applied to the weak-signal portion.  Strong and
! weak signals are finally re-combined in the time domain.

  parameter (MAXFFT=32768,MAXNH=MAXFFT/2)
  parameter (MAXSIGS=100)
  complex cx0(0:nfft-1),cx1(0:nfft-1)
  complex cx(0:MAXFFT-1),cxt(0:MAXFFT-1)
  complex cxs(0:MAXFFT-1),covxs(0:MAXNH-1)     !Strong X signals
  complex cxw(0:MAXFFT-1),covxw(0:MAXNH-1)     !Weak X signals
  complex cxw2(0:8191)
  complex cxs2(0:8191)
  real*4 w(0:MAXFFT-1)
  real*4 s(0:MAXFFT-1)
  logical*1 lstrong(0:MAXFFT-1),lprev
  integer ia(MAXSIGS),ib(MAXSIGS)
  logical first
  data first/.true./
  data k0/99999999/
  save

  if(first) then
     pi=4.0*atan(1.0)
     do i=0,nfft-1
        w(i)=(sin(i*pi/nfft))**2
     enddo
     s=0.
     nh=nfft/2
     nfft2=nfft/4
     if(ntrperiod.ge.300) nfft2=nfft/32
     nh2=nfft2/2
     kstep=nfft
     if(nwindow.eq.2) kstep=nh
     fac=1.0/nfft
     slimit=1.e30
     first=.false.
  endif

  if(k.lt.k0) then
     covxs=0.
     covxw=0.
  endif
  k0=k

  cx(0:nfft-1)=cx0
  if(nwindow.eq.2) cx(0:nfft-1)=w(0:nfft-1)*cx(0:nfft-1)
  call four2a(cx,nfft,1,-1,0)              !First forward FFT, r2c
  cxt(0:nfft-1)=cx(0:nfft-1)

! Identify frequencies with strong signals, copy frequency-domain
! data into array cs (strong) or cw (weak).

  do i=0,nfft-1
     s(i)=real(cxt(i))**2 + aimag(cxt(i))**2
  enddo
  ave=sum(s(0:nfft-1))/nfft
  lstrong(0:nfft-1)=s(0:nfft-1).gt.10.0*ave

  nsigs=0
  lprev=.false.
  iwid=1
  ib=-99
  do i=0,nfft-1
     if(lstrong(i) .and. (.not.lprev)) then
        if(nsigs.lt.MAXSIGS) nsigs=nsigs+1
        ia(nsigs)=i-iwid
        if(ia(nsigs).lt.0) ia(nsigs)=0
     endif
     if(.not.lstrong(i) .and. lprev) then
        ib(nsigs)=i-1+iwid
        if(ib(nsigs).gt.nfft-1) ib(nsigs)=nfft-1
     endif
     lprev=lstrong(i)
  enddo

  if(nsigs.gt.0) then
     do i=1,nsigs
        ja=ia(i)
        jb=ib(i)
        if(ja.lt.0 .or. ja.gt.nfft-1 .or. jb.lt.0 .or. jb.gt.nfft-1) then
           cycle
        endif
        if(jb.eq.-99) jb=ja + min(2*iwid,nfft-1)
        lstrong(ja:jb)=.true.
     enddo
  endif

  do i=0,nfft-1
     if(lstrong(i)) then
        cxs(i)=fac*cxt(i)
        cxw(i)=0.
     else
        cxs(i)=0.
        cxw(i)=fac*cxt(i)
     endif
  enddo

  df=12000.0/nfft
  i0=nint(1500.0/df)
  cxw2(0:nh2)=cxw(i0:i0+nh2)
  cxw2(nfft2-nh2:nfft2-1)=cxw(i0-nh2:i0-1)
  cxs2(0:nh2)=cxs(i0:i0+nh2)
  cxs2(nfft2-nh2:nfft2-1)=cxs(i0-nh2:i0-1)

  call four2a(cxw2,nfft2,1,1,1)                 !Transform weak and strong X
  call four2a(cxs2,nfft2,1,1,1)                 !back to time domain, separately

  if(nwindow.eq.2) then
     cxw2(0:nh2-1)=cxw2(0:nh2-1)+covxw(0:nh2-1) !Add prev segment's 2nd half
     covxw(0:nh2-1)=cxw2(nh2:nfft2-1)           !Save 2nd half
     cxs2(0:nh2-1)=cxs2(0:nh2-1)+covxs(0:nh2-1) !Ditto for strong signals
     covxs(0:nh2-1)=cxs2(nh2:nfft2-1)
  endif

! Apply noise blanking to weak data
  if(nb.ne.0) then
     do i=0,kstep-1
        peak=abs(cxw(i))
        if(peak.gt.peaklimit) then
           cxw2(i)=0.
           nzap=nzap+1
        endif
     enddo
  endif

! Compute power levels from weak data only
  px=0.
  do i=0,kstep-1
     px=px + real(cxw2(i))**2 + aimag(cxw2(i))**2
  enddo

  cx1(0:kstep-1)=cxw2(0:kstep-1) + cxs2(0:kstep-1)       !Weak + strong

  return
end subroutine timf2x
