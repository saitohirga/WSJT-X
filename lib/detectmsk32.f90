subroutine detectmsk32(cbig,n,mycall,partnercall,lines,nmessages,nutc,ntol,t00)
  use timer_module, only: timer

  parameter (NSPM=192, NPTS=3*NSPM, MAXSTEPS=7500, NFFT=3*NSPM, MAXCAND=5)
  character*4 rpt(0:63)
  character*6 mycall,partnercall
  character*22 msg,msgsent,msgreceived,allmessages(32)
  character*80 lines(100)
  complex bb(6)
  complex cbig(n)
  complex cdat(NPTS)                    !Analytic signal
  complex ctmp(NPTS)                    !Analytic signal
  complex cft(512)
  complex cwaveforms(192,64)
  integer, dimension(1) :: iloc
  integer indices(MAXSTEPS)
  integer itone(144)
  logical ismask(NFFT)
  real detmet(-2:MAXSTEPS+3)
  real detfer(MAXSTEPS)
  real ferrs(MAXCAND)
  real f2(64)
  real peak(64)
  real pp(12)
  real rcw(12)
  real snrs(MAXCAND)
  real times(MAXCAND)
  real tonespec(NFFT)
  real*8 dt, df, fs, pi, twopi
  logical first
  data first/.true./

  save df,first,cb,cbr,fs,nhashes,pi,twopi,dt,rcw,pp,nmatchedfilter,cwaveforms,rpt

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

     dphi0=twopi*(freq-500)/12000.0
     dphi1=twopi*(freq+500)/12000.0
     do i=1,64
       msg='<'//trim(mycall)//' '//trim(partnercall)//'> '//rpt(i-1)
       call genmsk32(msg,msgsent,0,itone,itype)
!     write(*,*) i,msg,msgsent,itype
       nsym=32
       phi=0.0
       indx=1
       nreps=1
       do jrep=1,nreps
         do isym=1,nsym
           if( itone(isym) .eq. 0 ) then
             dphi=dphi0
           else
             dphi=dphi1
           endif
           do j=1,6
             cwaveforms(indx,i)=cmplx(cos(phi),sin(phi));
             indx=indx+1
             phi=mod(phi+dphi,twopi)
           enddo
         enddo
       enddo
     enddo

     first=.false.
  endif

! Fill the detmet, detferr arrays
  nstepsize=48  ! 4ms steps
  nstep=(n-NPTS)/nstepsize  
  detmet=0
  detmax=-999.99
  detfer=-999.99
  do istp=1,nstep
    ns=1+nstepsize*(istp-1)
    ne=ns+NPTS-1
    if( ne .gt. n ) exit
    ctmp=cmplx(0.0,0.0)
    ctmp(1:NPTS)=cbig(ns:ne)

! Coarse carrier frequency sync - seek tones at 2000 Hz and 4000 Hz in 
! squared signal spectrum.
! search range for coarse frequency error is +/- 100 Hz

    ctmp=ctmp**2
    ctmp(1:12)=ctmp(1:12)*rcw
    ctmp(NPTS-11:NPTS)=ctmp(NPTS-11:NPTS)*rcw(12:1:-1)
    call four2a(ctmp,NFFT,1,-1,1)
    tonespec=abs(ctmp)**2

    ihlo=(4000-2*ntol)/df+1
    ihhi=(4000+2*ntol)/df+1
    ismask=.false.
    ismask(ihlo:ihhi)=.true.  ! high tone search window
    iloc=maxloc(tonespec,ismask)
    ihpk=iloc(1)
    deltah=-real( (ctmp(ihpk-1)-ctmp(ihpk+1)) / (2*ctmp(ihpk)-ctmp(ihpk-1)-ctmp(ihpk+1)) )
    ah=tonespec(ihpk)
    illo=(2000-2*ntol)/df+1
    ilhi=(2000+2*ntol)/df+1
    ismask=.false.
    ismask(illo:ilhi)=.true.   ! window for low tone
    iloc=maxloc(tonespec,ismask)
    ilpk=iloc(1)
    deltal=-real( (ctmp(ilpk-1)-ctmp(ilpk+1)) / (2*ctmp(ilpk)-ctmp(ilpk-1)-ctmp(ilpk+1)) )
    al=tonespec(ilpk)
    fdiff=(ihpk+deltah-ilpk-deltal)*df
    i2000=2000/df+1
    i4000=4000/df+1
    ferrh=(ihpk+deltah-i4000)*df/2.0
    ferrl=(ilpk+deltal-i2000)*df/2.0
    if( ah .ge. al ) then
      ferr=ferrh
    else
      ferr=ferrl
    endif
    detmet(istp)=max(ah,al)
    detfer(istp)=ferr
!    write(*,*) istp,ilpk,ihpk,ah,al
  enddo  ! end of detection-metric and frequency error estimation loop

  call indexx(detmet(1:nstep),nstep,indices) !find median of detection metric vector
  xmed=detmet(indices(nstep/4))
  detmet=detmet/xmed ! noise floor of detection metric is 1.0
  ndet=0

!do i=1,nstep
!write(77,*) i,detmet(i),detfer(i)
!enddo

  do ip=1,MAXCAND ! find candidates
    iloc=maxloc(detmet(1:nstep))
    il=iloc(1)
    if( (detmet(il) .lt. 4.2) ) exit 
    if( abs(detfer(il)) .le. ntol ) then 
      ndet=ndet+1
      times(ndet)=((il-1)*nstepsize+NPTS/2)*dt
      ferrs(ndet)=detfer(il)
      snrs(ndet)=12.0*log10(detmet(il)-1)/2-8.0
    endif
    detmet(max(1,il-3):min(nstep,il+3))=0.0
!    detmet(il)=0.0
  enddo

  nmessages=0
  lines=char(0)

  pkbest=-1.0
  ratbest=0.0
  imsgbest=-1
  fbest=0.0
  ipbest=-1
  nsnrbest=-1

  do ip=1,ndet  !run through the candidates and try to sync/demod/decode
    imid=times(ip)*fs
    if( imid .lt. NPTS/2 ) imid=NPTS/2
    if( imid .gt. n-NPTS/2 ) imid=n-NPTS/2
    t0=times(ip) + t00
    cdat=cbig(imid-NPTS/2+1:imid+NPTS/2)
    ferr=ferrs(ip)
    nsnr=nint(snrs(ip))
    if( nsnr .lt. -5 ) nsnr=-5
    if( nsnr .gt. 25 ) nsnr=25

    ic0=NSPM
    do i=1,6
!      if( ic0+11+NSPM .le. NPTS ) then
        bb(i) = sum( ( cdat(ic0+i-1+6:ic0+i-1+6+NSPM:6) * conjg( cdat(ic0+i-1:ic0+i-1+NSPM:6) ) )**2 )
!      else
!        bb(i) = sum( ( cdat(ic0+i-1+6:NPTS:6) * conjg( cdat(ic0+i-1:NPTS-6:6) ) )**2 )
!      endif
!      write(*,*) ip,i,abs(bb(i))
    enddo
    iloc=maxloc(abs(bb))
    ibb=iloc(1)
    bba=abs(bb(ibb))
    bbp=atan2(-imag(bb(ibb)),-real(bb(ibb)))/(2*twopi*6*dt)
    if( ibb .le. 3 ) ibb=ibb-1
    if( ibb .gt. 3 ) ibb=ibb-7
!    write(*,*) ibb
    ic0=ic0+ibb+2

    do istart=ic0,ic0+32*6-1,6
      do imsg=1,64
        cft(1:144)=cdat(istart:istart+144-1)*conjg(cwaveforms(1:144,imsg))
        cft(145:512)=0.
        df=12000.0/512.0
        call four2a(cft,512,1,-1,1)
        iloc=maxloc(abs(cft)) 
        ipk=iloc(1)
        pk=abs(cft(ipk))
        fpk=(ipk-1)*df
        if( fpk.gt.12000.0 ) fpk=fpk-12000.0
        f2(imsg)=fpk
        peak(imsg)=pk
      enddo
    iloc=maxloc(peak)
    imsg1=iloc(1)
    pk1=peak(imsg1)
    peak(imsg1)=-1
    pk2=maxval(peak)
    rat=pk1/pk2
    if( abs(f2(imsg1)-1500) .le. ntol .and. (pk1 .gt. pkbest) ) then
      pkbest=pk1
      ratbest=rat
      imsgbest=imsg1
      fbest=f2(imsg1)
      ipbest=ip
      t0best=t0
      nsnrbest=nsnr
      istartbest=istart
    endif
    enddo
!    write(*,*) ip,imid,istart,imsgbest,pkbest,ratbest,nsnrbest
!    if( pkbest .gt. 110.0 .and. ratbest .gt. 1.2 ) goto 999

  enddo  ! candidate loop

999 continue
  msgreceived=' '
  if( imsgbest .gt. 0 .and. pkbest .ge. 110.0 .and. ratbest .ge. 1.20) then
           nrxrpt=iand(imsgbest-1,63)
!write(*,*) ipbest,pkbest,fbest,imsgbest,istartbest,nsnrbest,t0best
           nmessages=1
           write(msgreceived,'(a1,a,1x,a,a1,1x,a4)') "<",trim(mycall),      &
                trim(partnercall),">",rpt(nrxrpt)
           write(lines(nmessages),1020) nutc,nsnrbest,t0best,nint(fbest),msgreceived
1020       format(i6.6,i4,f5.1,i5,' & ',a22)
  endif

  return
end subroutine detectmsk32
