subroutine detectmsk32(cbig,n,mycall,hiscall,lines,nmessages,nutc,ntol,t00)
  use timer_module, only: timer

  parameter (NSPM=192, NPTS=3*NSPM, MAXSTEPS=7500, NFFT=3*NSPM, MAXCAND=5,NWIN=15*NSPM)
  character*4 rpt(0:63)
  character*6 mycall,hiscall
  character*6 mycall0,hiscall0
  character*22 msg,msgsent,msgreceived,allmessages(32)
  character*80 lines(100)
  complex cbig(n)
!  complex cdat(0:NWIN-1)     
  complex cdat(0:n-1)     
  complex ctmp(NPTS)    
!  complex c(0:NWIN-1)      
  complex c(0:n-1)      
  complex cmsg(0:NSPM-1,0:63)
  complex z
  integer iloc(1)
  integer ipk0(1)
  integer indices(MAXSTEPS)
  integer itone(144)
  logical ismask(NFFT)
  real a(3)
  real detmet(-2:MAXSTEPS+3)
  real detfer(MAXSTEPS)
  real ferrs(MAXCAND)
  real f2(64)
  real peak(64)
  real pp(12)
  real p0(0:NSPM-1)
  real p(0:NSPM-1)
  real rcw(12)
  real snrs(MAXCAND)
  real s0(0:63)
  real times(MAXCAND)
  real tonespec(NFFT)
  real*8 dt, df, fs, pi, twopi
  logical first
  equivalence (ipk0,ipk)
  data first/.true./
  save df,first,cb,cbr,fs,nhashes,pi,twopi,dt,rcw,pp,nmatchedfilter,cmsg,rpt,mycall0,hiscall0

  if(first) then
     nmatchedfilter=1
! define half-sine pulse and raised-cosine edge window
     pi=4d0*datan(1d0)
     twopi=8d0*datan(1d0)
     fs=12000.0
     dt=1.0/fs
     df=fs/NFFT

     do i=1,12
       angle=(i-1)*pi/12.0
       pp(i)=sin(angle)
       rcw(i)=(1-cos(angle))/2
     enddo

     do i=0,30
       if( i.lt.5 ) then
         write(rpt(i),'(a1,i2.2,a1)') '-',abs(i-5)
         write(rpt(i+31),'(a2,i2.2,a1)') 'R-',abs(i-5)
       else
         write(rpt(i),'(a1,i2.2,a1)') '+',i-5
         write(rpt(i+31),'(a2,i2.2,a1)') 'R+',i-5
       endif
     enddo
     rpt(62)='RRR '
     rpt(63)='73  '

     mycall0='      '
     hiscall0='      '
     first=.false.
  endif

  if(mycall .ne. mycall0 .or. hiscall .ne. hiscall0 ) then
     freq=1500.0
     nsym=32
     dphi0=twopi*(freq-500)/12000.0
     dphi1=twopi*(freq+500)/12000.0
     do i=0,63
       msg='<'//trim(mycall)//' '//trim(hiscall)//'> '//rpt(i)
       call genmsk32(msg,msgsent,0,itone,itype)
       phi=0.0
       indx=0
       nreps=1
       do jrep=1,nreps
         do isym=1,nsym
           if( itone(isym) .eq. 0 ) then
             dphi=dphi0
           else
             dphi=dphi1
           endif
           do j=1,6
             cmsg(indx,i)=cmplx(cos(phi),sin(phi));
             indx=indx+1
             phi=mod(phi+dphi,twopi)
           enddo
         enddo
       enddo
     enddo
     mycall0=mycall
     hiscall0=hiscall
  endif

  cdat(0:n-1)=cbig
  sbest=0.0
  ibest=-1
  do imsg=0,63
    do idf=0,0
      if( idf.eq.0 ) then
        delf=0.0
      else if( mod(idf,2).eq.1 ) then
        delf=10*(idf+1)/2
      else
        delf=-10*idf/2
      endif
      a(1)=-delf
      a(2:3)=0.
      call twkfreq(cdat,c,n,12000.0,a)
      smax=0.
      p=0.
      fac=1.0/192
      do j=0,n-NSPM-1,2
        z=fac*dot_product(c(j:j+NSPM-1),cmsg(0:NSPM-1,imsg))
        s=real(z)**2 + aimag(z)**2
        k=mod(j,NSPM)
        p(k)=p(k)+s
        if( s.gt.smax) then
          smax=s
          jpk=j
          if( smax.gt.sbest) then
            sbest=smax
            p0=p
            ibest=imsg
            f0=1500+delf
          endif
        endif
      enddo  ! time loop
      s0(imsg)=smax
    enddo  ! frequency loop
  enddo  ! message loop

  ipk0=maxloc(p0)
  ps=0.
  sq=0.
  ns=0  
  pmax=0.
  do i=0,NSPM-1,2
    j=ipk-i
    if(j.gt.96) j=j-192
    if(j.lt.-96) j=j+192
    if(abs(j).gt.4) then
      ps=ps+p0(i)
      sq=sq+p0(i)**2
      ns=ns+1
    endif
  enddo
  avep=ps/ns
  rmsp=sqrt(sq/ns-avep*avep)
  p0=(p0-avep)/rmsp
  p1=maxval(p0)

!  do i=0,NSPM-1,2
!    write(14,1030) i,i/12000.0,p0(i)
!1030  format(i5,f10.6,f10.3)
!  enddo

  ave=(sum(s0)-sbest)/63
  s0=s0-ave
  s1=sbest-ave
  s2=0.
  do i=0,63
    if(i.ne.ibest .and. s0(i).gt.s2) s2=s0(i)
!    write(15,1020) i,idf,jpk/12000.0,s0(i)
!1020 format(2i6,2f10.2)
  enddo

  r1=s1/s2
  r2=r1+p1
  msg="                      "
!  write(*,'(i6.6,3f7.1,i5,2x,a22)') nutc,r1,p1,r2,ibest
  nmessages=0
  lines=char(0)
  if(r2.gt.7.0) then 
    t0=0.0
    nsnr=0.0
    msgreceived=' '
    nrxrpt=iand(ibest,63)
    nmessages=1
    write(msgreceived,'(a1,a,1x,a,a1,1x,a4)') "<",trim(mycall),      &
    trim(hiscall),">",rpt(nrxrpt)
    write(lines(nmessages),1021) nutc,nsnr,t0,nint(f0),msgreceived
1021 format(i6.6,i4,f5.1,i5,' & ',a22)
  endif
  return
end subroutine detectmsk32
