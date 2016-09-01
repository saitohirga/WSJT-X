subroutine detectmsk144(cbig,n,lines,nmessages,nutc,ntol,t00)
  use timer_module, only: timer

  parameter (NSPM=864, NPTS=3*NSPM, MAXSTEPS=1700, NFFT=NSPM, MAXCAND=16)
  character*22 msgreceived,allmessages(20)
  character*80 lines(100)
  complex cbig(n)
  complex cdat(NPTS)                    !Analytic signal
  complex cdat2(NPTS)
  complex c(NSPM)
  complex ctmp(NFFT)                  
  complex cb(42)                        !Complex waveform for sync word 
  complex cbr(42)                       !Complex waveform for reversed sync word 
  complex cfac,cca,ccb
  complex cc(NPTS)
  complex ccr(NPTS)
  complex cc1(NPTS)
  complex cc2(NPTS)
  complex ccr1(NPTS)
  complex ccr2(NPTS)
  complex bb(6)
  integer s8(8),s8r(8),hardbits(144)
  integer, dimension(1) :: iloc
  integer*1 decoded(80)   
  integer indices(MAXSTEPS)
  integer ipeaks(10)
  logical ismask(NFFT)
  real cbi(42),cbq(42)
  real detmet(-2:MAXSTEPS+3)
  real detmet2(-2:MAXSTEPS+3)
  real detfer(MAXSTEPS)
  real rcw(12)
  real dd(NPTS)
!  real ddr(NPTS)
  real ferrs(MAXCAND)
  real pp(12)                          !Half-sine pulse shape
  real snrs(MAXCAND)
  real times(MAXCAND)
  real tonespec(NFFT)
  real*8 dt, df, fs, pi, twopi
  real softbits(144)
  real*8 lratio(128)
  real llr(128)
  logical first
  data first/.true./
  data s8/0,1,1,1,0,0,1,0/
  data s8r/1,0,1,1,0,0,0,1/
  save df,first,cb,fs,pi,twopi,dt,s8,rcw,pp,nmatchedfilter

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

! define the sync word waveforms
     s8=2*s8-1  
     cbq(1:6)=pp(7:12)*s8(1)
     cbq(7:18)=pp*s8(3)
     cbq(19:30)=pp*s8(5)
     cbq(31:42)=pp*s8(7)
     cbi(1:12)=pp*s8(2)
     cbi(13:24)=pp*s8(4)
     cbi(25:36)=pp*s8(6)
     cbi(37:42)=pp(1:6)*s8(8)
     cb=cmplx(cbi,cbq)
     s8r=2*s8r-1  
     cbq(1:6)=pp(7:12)*s8r(1)
     cbq(7:18)=pp*s8r(3)
     cbq(19:30)=pp*s8r(5)
     cbq(31:42)=pp*s8r(7)
     cbi(1:12)=pp*s8r(2)
     cbi(13:24)=pp*s8r(4)
     cbi(25:36)=pp*s8r(6)
     cbi(37:42)=pp(1:6)*s8r(8)
     cbr=cmplx(cbi,cbq)

     first=.false.
  endif

  ! fill the detmet, detferr arrays
  nstep=(n-NPTS)/216  ! 72ms/4=18ms steps
  detmet=0
  detmet2=0
  detfer=-999.99
  do istp=1,nstep
    ns=1+216*(istp-1)
    ne=ns+NSPM-1
    if( ne .gt. n ) exit
    ctmp=cmplx(0.0,0.0)
    ctmp(1:NSPM)=cbig(ns:ne)

! Coarse carrier frequency sync - seek tones at 2000 Hz and 4000 Hz in 
! squared signal spectrum.
! search range for coarse frequency error is +/- 100 Hz

    ctmp=ctmp**2
    ctmp(1:12)=ctmp(1:12)*rcw
    ctmp(NSPM-11:NSPM)=ctmp(NSPM-11:NSPM)*rcw(12:1:-1)
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
    ahavp=(sum(tonespec,ismask)-ah)/count(ismask)
    trath=ah/(ahavp+0.01)
    illo=(2000-2*ntol)/df+1
    ilhi=(2000+2*ntol)/df+1
    ismask=.false.
    ismask(illo:ilhi)=.true.   ! window for low tone
    iloc=maxloc(tonespec,ismask)
    ilpk=iloc(1)
    deltal=-real( (ctmp(ilpk-1)-ctmp(ilpk+1)) / (2*ctmp(ilpk)-ctmp(ilpk-1)-ctmp(ilpk+1)) )
    al=tonespec(ilpk)
    alavp=(sum(tonespec,ismask)-al)/count(ismask)
    tratl=al/(alavp+0.01)
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
    detmet2(istp)=max(trath,tratl)
    detfer(istp)=ferr
  enddo  ! end of detection-metric and frequency error estimation loop

  call indexx(detmet(1:nstep),nstep,indices) !find median of detection metric vector
  xmed=detmet(indices(nstep/4))
  detmet=detmet/xmed ! noise floor of detection metric is 1.0
  ndet=0

  do ip=1,MAXCAND ! Find candidates
    iloc=maxloc(detmet(1:nstep))
    il=iloc(1)
    if( (detmet(il) .lt. 4.0) ) exit 
    if( abs(detfer(il)) .le. ntol ) then 
      ndet=ndet+1
      times(ndet)=((il-1)*216+NSPM/2)*dt
      ferrs(ndet)=detfer(il)
      snrs(ndet)=12.0*log10(detmet(il))/2-9.0
    endif
!    detmet(max(1,il-1):min(nstep,il+1))=0.0
    detmet(il)=0.0
  enddo

  if( ndet .lt. 3 ) then  
    do ip=1,MAXCAND-ndet ! Find candidates
      iloc=maxloc(detmet2(1:nstep))
      il=iloc(1)
      if( (detmet2(il) .lt. 12.0) ) exit 
      if( abs(detfer(il)) .le. ntol ) then 
        ndet=ndet+1
        times(ndet)=((il-1)*216+NSPM/2)*dt
        ferrs(ndet)=detfer(il)
        snrs(ndet)=12.0*log10(detmet2(il))/2-9.0
      endif
!     detmet2(max(1,il-1):min(nstep,il+1))=0.0
      detmet2(il)=0.0
    enddo
  endif

  nmessages=0
  allmessages=char(0)
  lines=char(0)
  nshort=0

  do ip=1,ndet  ! Try to sync/demod/decode each candidate.
    imid=times(ip)*fs
    if( imid .lt. NPTS/2 ) imid=NPTS/2
    if( imid .gt. n-NPTS/2 ) imid=n-NPTS/2
    t0=times(ip) + t00
    cdat=cbig(imid-NPTS/2+1:imid+NPTS/2)
    ferr=ferrs(ip)
    nsnr=2*nint(snrs(ip)/2.0)
    if( nsnr .lt. -4 ) nsnr=-4
    if( nsnr .gt. 24 ) nsnr=24

! remove coarse freq error - should now be within a few Hz
    call tweak1(cdat,NPTS,-(1500+ferr),cdat)
  
! attempt frame synchronization
! correlate with sync word waveforms
    cc=0
    ccr=0
    cc1=0
    cc2=0
    ccr1=0
    ccr2=0
    do i=1,NPTS-(56*6+41)
      cc1(i)=sum(cdat(i:i+41)*conjg(cb))
      cc2(i)=sum(cdat(i+56*6:i+56*6+41)*conjg(cb))
    enddo
    cc=cc1+cc2
    dd=abs(cc1)*abs(cc2)
!    do i=1,NPTS-(40*6+41)
!      ccr1(i)=sum(cdat(i:i+41)*conjg(cbr))
!      ccr2(i)=sum(cdat(i+40*6:i+40*6+41)*conjg(cbr))
!    enddo
!    ccr=ccr1+ccr2
!    ddr=abs(ccr1)*abs(ccr2)
    cmax=maxval(abs(cc))
!    crmax=maxval(abs(ccr))
!    if( crmax .gt. cmax ) then
!      nshort=nshort+1
!    endif
 
! Find 6 largest peaks
    do ipk=1, 6
      iloc=maxloc(abs(cc))
      ic1=iloc(1)
      iloc=maxloc(dd)
      ic2=iloc(1)
      ipeaks(ipk)=ic2
      dd(max(1,ic2-7):min(NPTS-56*6-41,ic2+7))=0.0
!      ipeaks(ipk)=ic1
!      cc(max(1,ic1-7):min(NPTS-56*6-41,ic1+7))=0.0
!write(*,*) ipk,ic2
    enddo

    do ipk=1,6

! we want ic to be the index of the first sample of the frame
      ic0=ipeaks(ipk)

! fine adjustment of sync index
      do i=1,6
        if( ic0+11+NSPM .le. NPTS ) then
          bb(i) = sum( ( cdat(ic0+i-1+6:ic0+i-1+6+NSPM:6) * conjg( cdat(ic0+i-1:ic0+i-1+NSPM:6) ) )**2 )
        else
          bb(i) = sum( ( cdat(ic0+i-1+6:NPTS:6) * conjg( cdat(ic0+i-1:NPTS-6:6) ) )**2 )
        endif
      enddo
      iloc=maxloc(abs(bb))
      ibb=iloc(1)
      bba=abs(bb(ibb))
      bbp=atan2(-imag(bb(ibb)),-real(bb(ibb)))/(2*twopi*6*dt)
      if( ibb .le. 3 ) ibb=ibb-1
      if( ibb .gt. 3 ) ibb=ibb-7

      do id=1,3     ! Slicer dither. 
        if( id .eq. 1 ) is=0
        if( id .eq. 2 ) is=-1
        if( id .eq. 3 ) is=1

! Adjust frame index to place peak of bb at desired lag
        ic=ic0+ibb+is
        if( ic .lt. 1 ) ic=ic+864

! Estimate fine frequency error. 
! Should a larger separation be used when frames are averaged?
        cca=sum(cdat(ic:ic+41)*conjg(cb))
        if( ic+56*6+41 .le. NPTS ) then
          ccb=sum(cdat(ic+56*6:ic+56*6+41)*conjg(cb))
          cfac=ccb*conjg(cca)
          ferr2=atan2(imag(cfac),real(cfac))/(twopi*56*6*dt)
        else
          ccb=sum(cdat(ic-88*6:ic-88*6+41)*conjg(cb))
          cfac=cca*conjg(ccb)
          ferr2=atan2(imag(cfac),real(cfac))/(twopi*88*6*dt)
        endif

! Final estimate of the carrier frequency - returned to the calling program
          fest=1500+ferr+ferr2 

        do idf=0,4   ! frequency jitter
          if( idf .eq. 0 ) then
            deltaf=0.0
          elseif( mod(idf,2) .eq. 0 ) then
            deltaf=idf
          else
            deltaf=-(idf+1)
          endif

! Remove fine frequency error
          call tweak1(cdat,NPTS,-(ferr2+deltaf),cdat2)

! place the beginning of frame at index NSPM+1
          cdat2=cshift(cdat2,ic-(NSPM+1))

          do iav=1,8 ! Hopefully we can eliminate some of these after looking at more examples 
            if( iav .eq. 1 ) then
              c=cdat2(NSPM+1:2*NSPM)  
            elseif( iav .eq. 2 ) then
              c=cdat2(NSPM-431:NSPM+432)  
              c=cshift(c,-432)
            elseif( iav .eq. 3 ) then         
              c=cdat2(2*NSPM-431:2*NSPM+432)  
              c=cshift(c,-432)
            elseif( iav .eq. 4 ) then
              c=cdat2(1:NSPM)
            elseif( iav .eq. 5 ) then
              c=cdat2(2*NSPM+1:NPTS) 
            elseif( iav .eq. 6 ) then
              c=cdat2(1:NSPM)+cdat2(NSPM+1:2*NSPM)
            elseif( iav .eq. 7 ) then
              c=cdat2(NSPM+1:2*NSPM)+cdat2(2*NSPM+1:NPTS)
            elseif( iav .eq. 8 ) then
              c=cdat2(1:NSPM)+cdat2(NSPM+1:2*NSPM)+cdat2(2*NSPM+1:NPTS)
            endif

! Estimate final frequency error and carrier phase. 
            cca=sum(c(1:1+41)*conjg(cb))
            ccb=sum(c(1+56*6:1+56*6+41)*conjg(cb))
            cfac=ccb*conjg(cca)
            ffin=atan2(imag(cfac),real(cfac))/(twopi*56*6*dt)
            phase0=atan2(imag(cca+ccb),real(cca+ccb))

            do ipha=1,1
              if( ipha.eq.2 ) phase0=phase0+30*pi/180.0
              if( ipha.eq.3 ) phase0=phase0-30*pi/180.0

! Remove phase error - want constellation rotated so that sample points lie on I/Q axes
              cfac=cmplx(cos(phase0),sin(phase0))
              c=c*conjg(cfac)

              if( nmatchedfilter .eq. 0 ) then
! sample to get softsamples
                do i=1,72
                  softbits(2*i-1)=imag(c(1+(i-1)*12))
                  softbits(2*i)=real(c(7+(i-1)*12))  
                enddo
              else
! matched filter - 
! how much mismatch does the RX/TX/analytic filter cause?, how rig (pair) dependent is this loss?
                softbits(1)=sum(imag(c(1:6))*pp(7:12))+sum(imag(c(864-5:864))*pp(1:6))
                softbits(2)=sum(real(c(1:12))*pp)
                do i=2,72
                  softbits(2*i-1)=sum(imag(c(1+(i-1)*12-6:1+(i-1)*12+5))*pp)
                  softbits(2*i)=sum(real(c(7+(i-1)*12-6:7+(i-1)*12+5))*pp)
                enddo
              endif

! sync word hard error weight is a good discriminator for 
! frames that have reasonable probability of decoding
              hardbits=0
              do i=1,144
                if( softbits(i) .ge. 0.0 ) then
                  hardbits(i)=1
                endif
              enddo
              nbadsync1=(8-sum( (2*hardbits(1:8)-1)*s8 ) )/2
              nbadsync2=(8-sum( (2*hardbits(1+56:8+56)-1)*s8 ) )/2
              nbadsync=nbadsync1+nbadsync2
              if( nbadsync .gt. 4 ) cycle

! normalize the softsymbols before submitting to decoder
              sav=sum(softbits)/144
              s2av=sum(softbits*softbits)/144
              ssig=sqrt(s2av-sav*sav)
              softbits=softbits/ssig

              sigma=0.75
              lratio(1:48)=softbits(9:9+47)
              lratio(49:128)=softbits(65:65+80-1)
              llr=2.0*lratio/(sigma*sigma)
              lratio=exp(2.0*lratio/(sigma*sigma))
  
              max_iterations=10
              max_dither=1
              call timer('bpdec144 ',0)
              call bpdecode144(llr,max_iterations,decoded,niterations)
              call timer('bpdec144 ',1)

              if( niterations .ge. 0.0 ) then
                call extractmessage144(decoded,msgreceived,nhashflag)
                if( nhashflag .gt. 0 ) then  ! CRCs match, so print it 
                  ndupe=0
                  do im=1,nmessages
                    if( allmessages(im) .eq. msgreceived ) ndupe=1
                  enddo
                  if( ndupe .eq. 0 ) then
                    nmessages=nmessages+1
                    allmessages(nmessages)=msgreceived
                    write(lines(nmessages),1020) nutc,nsnr,t0,nint(fest),msgreceived
1020                format(i6.6,i4,f5.1,i5,' & ',a22)
                  endif
                  goto 999
                else
                  msgreceived=' '
                  ndither=-99             ! -99 is bad hash flag
!                  write(78,1001) nutc,t0,nsnr,ip,ipk,is,idf,iav,ipha,deltaf,fest,ferr,ferr2, &
!                                 ffin,bba,bbp,nbadsync1,nbadsync2, &
!                                 phase0,niterations,ndither,msgreceived
                endif
              endif
            enddo ! phase dither
          enddo ! frame averaging loop
        enddo  ! frequency dithering loop
      enddo   ! sample-time dither loop
    enddo     ! peak loop - could be made more efficient by working harder to find good peaks

    msgreceived=' '
    ndither=-98   
999 continue
    if( nmessages .ge. 1 ) then 
!      write(78,1001) nutc,t0,nsnr,ip,ipk,is,idf,iav,ipha,deltaf,fest,ferr,ferr2,  &
!                     ffin,bba,bbp,nbadsync1,nbadsync2, &
!                     phase0,niterations,ndither,msgreceived
!      call flush(78)
!1001 format(i6.6,f8.2,i5,i5,i5,i5,i5,i5,i5,f6.2,f8.2,f8.2,f8.2,f8.2,f11.1,f8.2,i5,i5,f8.2,i5,i5,2x,a22)
      exit
    endif
  enddo
  return
end subroutine detectmsk144
