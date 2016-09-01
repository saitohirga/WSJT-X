subroutine detectmsk40(cbig,n,mycall,hiscall,lines,nmessages,   &
     nutc,ntol,t00)

  use timer_module, only: timer
  parameter (NSPM=240, NPTS=3*NSPM, MAXSTEPS=7500, NFFT=3*NSPM, MAXCAND=15)
  character*4 rpt(0:15)
  character*6 mycall,hiscall,mycall0,hiscall0
  character*22 hashmsg,msgreceived
  character*80 lines(100)
  complex cbig(n)
  complex cdat(NPTS)                    !Analytic signal
  complex cdat2(NPTS)
  complex c(NSPM)
  complex ctmp(NFFT)                  
  complex cb(42)                        !Complex waveform for sync word 
  complex cbr(42)                       !Complex waveform for reversed sync word
  complex cfac,cca,ccb
  complex ccr(NPTS)
  complex ccr1(NPTS)
  complex ccr2(NPTS)
  complex bb(6)
  integer s8(8),s8r(8),hardbits(40)
  integer, dimension(1) :: iloc
  integer nhashes(0:15)
  integer indices(MAXSTEPS)
  integer ipeaks(10)
  integer*1 cw(32)
  integer*1 decoded(16)
  integer*1 testcw(32)
  logical ismask(NFFT)
  real cbi(42),cbq(42)
  real detmet(-2:MAXSTEPS+3)
  real detmet2(-2:MAXSTEPS+3)
  real detfer(MAXSTEPS)
  real rcw(12)
  real ddr(NPTS)
  real ferrs(MAXCAND)
  real llr(32)
  real pp(12)                          !Half-sine pulse shape
  real snrs(MAXCAND)
  real softbits(40)
  real times(MAXCAND)
  real tonespec(NFFT)
  real*8 dt, df, fs, pi, twopi
  real*8 lratio(32)
  logical first
  data first/.true./
  data mycall0/'dummy'/,hiscall0/'dummy'/
  data rpt/"-03 ","+00 ","+03 ","+06 ","+10 ","+13 ","+16 ", &
           "R-03","R+00","R+03","R+06","R+10","R+13","R+16", &
           "RRR ","73  "/
  data s8/0,1,1,1,0,0,1,0/
  data s8r/1,0,1,1,0,0,0,1/
! codeword for the message <K9AN K1JT> RRR
  data testcw/0,1,0,0,0,1,0,1,0,0,1,1,1,1,0,1,0,1,1,1,1,1,0,0,0,0,0,0,1,1,1,0/
  save df,first,cb,cbr,fs,nhashes,pi,twopi,dt,s8,s8r,rcw,pp,nmatchedfilter,rpt,mycall0,hiscall0

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

  if(mycall.ne.mycall0 .or. hiscall.ne.hiscall0) then
     do i=0,15 
       hashmsg=trim(mycall)//' '//trim(hiscall)//' '//rpt(i)
       call fmtmsg(hashmsg,iz)
       call hash(hashmsg,22,ihash)
       nhashes(i)=iand(ihash,4095)
     enddo
     mycall0=mycall
     hiscall0=hiscall
  endif

! Fill the detmet, detferr arrays
  nstepsize=60  ! 5ms steps
  nstep=(n-NPTS)/nstepsize  
  detmet=0
  detmet2=0
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
    i2000=nint(2000/df)+1
    i4000=nint(4000/df)+1
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
!    write(*,*) istp,ilpk,ihpk,ah,al
  enddo  ! end of detection-metric and frequency error estimation loop

  call indexx(detmet(1:nstep),nstep,indices) !find median of detection metric vector
  xmed=detmet(indices(nstep/4))
  detmet=detmet/xmed ! noise floor of detection metric is 1.0
  ndet=0

!do i=1,nstep
!write(77,*) i,detmet(i),detmet2(i),detfer(i)
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

  if( ndet .lt. 3 ) then  
    do ip=1,MAXCAND-ndet ! Find candidates
      iloc=maxloc(detmet2(1:nstep))
      il=iloc(1)
      if( (detmet2(il) .lt. 20.0) ) exit 
      if( abs(detfer(il)) .le. ntol ) then 
        ndet=ndet+1
        times(ndet)=((il-1)*nstepsize+NSPM/2)*dt
        ferrs(ndet)=detfer(il)
        snrs(ndet)=12.0*log10(detmet2(il))/2-9.0
      endif
     detmet2(max(1,il-1):min(nstep,il+1))=0.0
!     detmet2(il)=0.0
    enddo
  endif

!  do ip=1,ndet
!    write(*,'(i5,f7.2,f7.2,f7.2)') ip,times(ip),snrs(ip),ferrs(ip)
!  enddo

  nmessages=0
  lines=char(0)
  
  ncalls=0
  do ip=1,ndet  !run through the candidates and try to sync/demod/decode
    imid=times(ip)*fs
    if( imid .lt. NPTS/2 ) imid=NPTS/2
    if( imid .gt. n-NPTS/2 ) imid=n-NPTS/2
    t0=times(ip) + t00
    cdat=cbig(imid-NPTS/2+1:imid+NPTS/2)
    ferr=ferrs(ip)
    xsnr=snrs(ip)
    nsnr=nint(snrs(ip))
    if( nsnr .lt. -5 ) nsnr=-5
    if( nsnr .gt. 25 ) nsnr=25

! remove coarse freq error
    call tweak1(cdat,NPTS,-(1500+ferr),cdat)

! attempt frame synchronization
! correlate with sync word waveforms
    ccr=0
    ccr1=0
    ccr2=0
    do i=1,NPTS-(40*6+41)
      ccr1(i)=sum(cdat(i:i+41)*conjg(cbr))
      ccr2(i)=sum(cdat(i+40*6:i+40*6+41)*conjg(cbr))
    enddo
    ccr=ccr1+ccr2
    ddr=abs(ccr1)*abs(ccr2)
    crmax=maxval(abs(ccr))

!do i=1,NPTS
!write(15,*) i,abs(ccr(i)),ddr(i),abs(cdat(i))
!enddo


! Find 6 largest peaks
    do ipk=1,6
      iloc=maxloc(ddr)
      ic1=iloc(1)
      ipeaks(ipk)=ic1
      ddr(max(1,ic1-7):min(NPTS-40*6-41,ic1+7))=0.0
    enddo
!do i=1,6
!write(*,*) i,ipeaks(i)
!enddo
    do ipk=1,4

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
!write(*,*) abs(bb),bbp
      if( ibb .le. 3 ) ibb=ibb-1
      if( ibb .gt. 3 ) ibb=ibb-7

      do id=1,3     ! slicer dither.
        if( id .eq. 1 ) is=0
        if( id .eq. 2 ) is=-1
        if( id .eq. 3 ) is=1

! Adjust frame index to place peak of bb at desired lag
        ic=ic0+ibb+is
        if( ic .lt. 1 ) ic=ic+NSPM

! Estimate fine frequency error. 
        cca=sum(cdat(ic:ic+41)*conjg(cbr))
        if( ic+40*6+41 .le. NPTS ) then
          ccb=sum(cdat(ic+40*6:ic+40*6+41)*conjg(cbr))
          cfac=ccb*conjg(cca)
          ferr2=atan2(imag(cfac),real(cfac))/(twopi*40*6*dt)
        else
          ccb=sum(cdat(ic-40*6:ic-40*6+41)*conjg(cbr))
          cfac=cca*conjg(ccb)
          ferr2=atan2(imag(cfac),real(cfac))/(twopi*40*6*dt)
        endif

        do idf=0,2                         ! frequency jitter
          if( idf .eq. 0 ) then
            deltaf=0.0
          elseif( mod(idf,2) .eq. 0 ) then
            deltaf=2.5*idf
          else
            deltaf=-2.5*(idf+1)
          endif

! Remove fine frequency error
          call tweak1(cdat,NPTS,-(ferr2+deltaf),cdat2)

! place the beginning of frame at index NSPM+1
          cdat2=cshift(cdat2,ic-(NSPM+1))

          do iav=1,4 ! Frame averaging patterns 
            if( iav .eq. 1 ) then
              c=cdat2(NSPM+1:2*NSPM)  
            elseif( iav .eq. 2 ) then
              c=cdat2(1:NSPM)+cdat2(NSPM+1:2*NSPM)
            elseif( iav .eq. 3 ) then
              c=cdat2(NSPM+1:2*NSPM)+cdat2(2*NSPM+1:3*NSPM)
            elseif( iav .eq. 4 ) then
              c=cdat2(1:NSPM)+cdat2(NSPM+1:2*NSPM)+cdat2(2*NSPM+1:3*NSPM)
            endif

! Estimate final frequency error and carrier phase. 
            cca=sum(c(1:1+41)*conjg(cbr))
            phase0=atan2(imag(cca),real(cca))

            do ipha=1,3
              if( ipha.eq.2 ) phase0=phase0-30*pi/180.0
              if( ipha.eq.3 ) phase0=phase0+30*pi/180.0

! Remove phase error - want constellation rotated so that sample points lie on I/Q axes
              cfac=cmplx(cos(phase0),sin(phase0))
              c=c*conjg(cfac)

              if( nmatchedfilter .eq. 0 ) then
                do i=1, 20 
                  softbits(2*i-1)=imag(c(1+(i-1)*12))
                  softbits(2*i)=real(c(7+(i-1)*12))  
                enddo
              else   ! matched filter
                softbits(1)=sum(imag(c(1:6))*pp(7:12))+sum(imag(c(NSPM-5:NSPM))*pp(1:6))
                softbits(2)=sum(real(c(1:12))*pp)
                do i=2,20
                  softbits(2*i-1)=sum(imag(c(1+(i-1)*12-6:1+(i-1)*12+5))*pp)
                  softbits(2*i)=sum(real(c(7+(i-1)*12-6:7+(i-1)*12+5))*pp)
                enddo
              endif

              hardbits=0  ! use sync word hard error weight to decide whether to send to decoder
              do i=1, 40 
                if( softbits(i) .ge. 0.0 ) then
                  hardbits(i)=1
                endif
              enddo
              nbadsync1=(8-sum( (2*hardbits(1:8)-1)*s8r ) )/2
              nbadsync=nbadsync1
              if( nbadsync .gt. 3 ) cycle
!              nerr=0
!              do i=1,32
!                if( testcw(i) .ne. hardbits(i+8) ) nerr=nerr+1
!              enddo
              ! normalize the softsymbols before submitting to decoder
              sav=sum(softbits)/40
              s2av=sum(softbits*softbits)/40
              ssig=sqrt(s2av-sav*sav)
              softbits=softbits/ssig

              sigma=0.75
              if(xsnr.lt.0.0) sigma=0.75-0.0875*xsnr 
              lratio(1:32)=exp(2.0*softbits(9:40)/(sigma*sigma)) ! Use this for Radford Neal's routines
              llr(1:32)=2.0*softbits(9:40)/(sigma*sigma)  ! Use log likelihood for bpdecode40

              max_iterations=5
              max_dither=1
              call bpdecode40(llr,max_iterations, decoded, niterations)
              ncalls=ncalls+1
               
              nhashflag=0
              if( niterations .ge. 0 ) then
                call encode_msk40(decoded,cw)
!                call ldpc_encode(decoded,cw)
                nhammd=0
                cord=0.0
                do i=1,32
                  if( cw(i) .ne. hardbits(i+8) ) then
                    nhammd=nhammd+1
                    cord=cord+abs(softbits(i+8))
                  endif
                enddo

                imsg=0
                do i=1,16
                  imsg=ishft(imsg,1)+iand(1,decoded(17-i))
                enddo
                nrxrpt=iand(imsg,15)
                nrxhash=(imsg-nrxrpt)/16
                if( nhammd .le. 5 .and. cord .lt. 1.7 .and. nrxhash .eq. nhashes(nrxrpt) ) then
                  fest=1500+ferr+ferr2+deltaf 
!write(14,'(i6.6,11i6,f7.1,f7.1)') nutc,ip,ipk,id,idf,iav,ipha,niterations,nbadsync,nrxrpt,ncalls,nhammd,cord,xsnr
                  nhashflag=1
                  msgreceived=' '
                  nmessages=1
                  write(msgreceived,'(a1,a,1x,a,a1,1x,a4)') "<",trim(mycall),      &
                                                trim(hiscall),">",rpt(nrxrpt)
                  write(lines(nmessages),1020) nutc,nsnr,t0,nint(fest),msgreceived
1020              format(i6.6,i4,f5.1,i5,' & ',a22)
                  return
                endif

              endif

            enddo   ! phase loop
          enddo   ! frame averaging loop
        enddo   ! frequency dithering loop
      enddo   ! slicer dither loop
    enddo   ! time-sync correlation-peak loop
  enddo  ! candidate loop
return
end subroutine detectmsk40
