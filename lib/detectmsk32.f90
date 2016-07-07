subroutine detectmsk32(cbig,n,mycall,partnercall,lines,nmessages,nutc)
  use timer_module, only: timer

  parameter (NSPM=192, NPTS=3*NSPM, MAXSTEPS=7500, NFFT=3*NSPM, MAXCAND=40)
  character*4 rpt(0:31)
  character*6 mycall,partnercall
  character*22 msg,hashmsg,msgreceived,allmessages(20)
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
  integer s8(8),s8r(8),hardbits(32)
  integer, dimension(1) :: iloc
  integer ihammd(0:4096-1)
  integer indices(MAXSTEPS)
  integer ipeaks(10)
  integer ig24(0:4096-1)
  integer likelymessages(0:31)
  logical qsocontext
  logical ismask(NFFT)
  real cbi(42),cbq(42)
  real cd(0:4095)
  real detmet(-2:MAXSTEPS+3)
  real detfer(MAXSTEPS)
  real rcw(12)
  real dd(NPTS)
  real ddr(NPTS)
  real ferrs(MAXCAND)
  real pp(12)                          !Half-sine pulse shape
  real snrs(MAXCAND)
  real times(MAXCAND)
  real tonespec(NFFT)
  real*8 dt, df, fs, pi, twopi
  real softbits(32)
  logical first
  data first/.true./
  data s8/0,1,1,1,0,0,1,0/
  data s8r/1,0,1,1,0,0,0,1/
  data rpt /'-04 ','-03 ','-02 ','-01 ','00 ','01 ','02 ','03 ','04 ', &
            '05 ','06 ','07 ','08 ','09 ','10 ', &
            'R-04','R-03','R-02','R-01','R00','R01','R02','R03','R04', &
            'R05','R06','R07','R08','R09','R10', &
            'RRR ','73  '/
  save df,first,cb,cbr,fs,pi,twopi,dt,s8,rcw,pp,nmatchedfilter,ig24

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

     call golay24_table(ig24)

     first=.false.
  endif

! Define the 32 likely messages 
  do irpt=0,31
    hashmsg=trim(mycall)//' '//trim(partnercall)//' '//rpt(irpt)
    call fmtmsg(hashmsg,iz)
    call hash(hashmsg,22,ihash)
    ihash=iand(ihash,127)
    ig=32*ihash + irpt
    likelymessages(irpt)=ig
!    write(*,*) irpt,hashmsg,ig,ig24(ig)
  enddo  
  qsocontext=.false.

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

    i3800=3800/df+1
    i4200=4200/df+1
    ismask=.false.
    ismask(i3800:i4200)=.true.  ! high tone search window
    iloc=maxloc(tonespec,ismask)
    ihpk=iloc(1)
    deltah=-real( (ctmp(ihpk-1)-ctmp(ihpk+1)) / (2*ctmp(ihpk)-ctmp(ihpk-1)-ctmp(ihpk+1)) )
    ah=tonespec(ihpk)
    i1800=1800/df+1
    i2200=2200/df+1
    ismask=.false.
    ismask(i1800:i2200)=.true.   ! window for low tone
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
!  xmed=detmet(indices(nstep/2))
  xmed=detmet(indices(nstep/4))
  detmet=detmet/xmed ! noise floor of detection metric is 1.0
  ndet=0

!do i=1,nstep
!write(77,*) i,detmet(i),detfer(i)
!enddo

  do ip=1,MAXCAND ! use something like the "clean" algorithm to find candidates
    iloc=maxloc(detmet(1:nstep))
    il=iloc(1)
    if( (detmet(il) .lt. 4.0) ) exit 
    if( abs(detfer(il)) .le. 100.0 ) then 
      ndet=ndet+1
      times(ndet)=((il-1)*nstepsize+NPTS/2)*dt
      ferrs(ndet)=detfer(il)
      snrs(ndet)=12.0*log10(detmet(il))/2-9.0
    endif
    detmet(max(1,il-5):min(nstep,il+5))=0.0
!    detmet(il)=0.0
  enddo
 
!  do ip=1,ndet
!    write(*,*) ip,times(ip),snrs(ip),ferrs(ip)
!  enddo

  nmessages=0
  allmessages=char(0)
  lines=char(0)

  imsgbest=-99
  nbadsyncbest=99
  cdbest=1e32
  cdratbest=0.0

  do ip=1,ndet  !run through the candidates and try to sync/demod/decode
    imid=times(ip)*fs
    if( imid .lt. NPTS/2 ) imid=NPTS/2
    if( imid .gt. n-NPTS/2 ) imid=n-NPTS/2
    t0=times(ip)
    cdat=cbig(imid-NPTS/2+1:imid+NPTS/2)
    ferr=ferrs(ip)
    nsnr=snrs(ip)

! remove coarse freq error - should now be within a few Hz
    call tweak1(cdat,NPTS,-(1500+ferr),cdat)

! attempt frame synchronization
! correlate with sync word waveforms
    ccr=0
    ccr1=0
    ccr2=0
    do i=1,NPTS-(32*6+41)
      ccr1(i)=sum(cdat(i:i+41)*conjg(cbr))
      ccr2(i)=sum(cdat(i+32*6:i+32*6+41)*conjg(cbr))
    enddo
    ccr=ccr1+ccr2
    ddr=abs(ccr1)*abs(ccr2)
    crmax=maxval(abs(ccr))

! Find 6 largest peaks
    do ipk=1,6
      iloc=maxloc(abs(ccr))
      ic1=iloc(1)
      iloc=maxloc(ddr)
      ic2=iloc(1)
      ipeaks(ipk)=ic1
      ccr(max(1,ic1-7):min(NPTS-32*6-41,ic1+7))=0.0
    enddo

    do ipk=1,2

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

      do id=1,1     ! slicer dither.
        if( id .eq. 1 ) is=0
        if( id .eq. 2 ) is=-1
        if( id .eq. 3 ) is=1

! Adjust frame index to place peak of bb at desired lag
        ic=ic0+ibb+is
        if( ic .lt. 1 ) ic=ic+NSPM

! Estimate fine frequency error. 
        cca=sum(cdat(ic:ic+41)*conjg(cb))
        if( ic+32*6+41 .le. NPTS ) then
          ccb=sum(cdat(ic+32*6:ic+32*6+41)*conjg(cb))
          cfac=ccb*conjg(cca)
          ferr2=atan2(imag(cfac),real(cfac))/(twopi*32*6*dt)
        else
          ccb=sum(cdat(ic-32*6:ic-32*6+41)*conjg(cb))
          cfac=cca*conjg(ccb)
          ferr2=atan2(imag(cfac),real(cfac))/(twopi*32*6*dt)
        endif

! Final estimate of the carrier frequency - returned to the calling program
        fest=1500+ferr+ferr2 

        do idf=0,6                         ! frequency jitter
          if( idf .eq. 0 ) then
            deltaf=0.0
          elseif( mod(idf,2) .eq. 0 ) then
            deltaf=4*idf
          else
            deltaf=-4*(idf+1)
          endif

! Remove fine frequency error
          call tweak1(cdat,NPTS,-(ferr2+deltaf),cdat2)

! place the beginning of frame at index NSPM+1
          cdat2=cshift(cdat2,ic-(NSPM+1))

          do iav=1,8 ! Frame averaging patterns 
            if( iav .eq. 1 ) then
              c=cdat2(NSPM+1:2*NSPM)  
            elseif( iav .eq. 2 ) then
              c=cdat2(NSPM-95:NSPM+96)  
              c=cshift(c,-96)
            elseif( iav .eq. 3 ) then         
              c=cdat2(2*NSPM-95:2*NSPM+96)  
              c=cshift(c,-96)
            elseif( iav .eq. 4 ) then
              c=cdat2(1:NSPM)
            elseif( iav .eq. 5 ) then
              c=cdat2(2*NSPM+1:3*NSPM) 
            elseif( iav .eq. 6 ) then
              c=cdat2(1:NSPM)+cdat2(NSPM+1:2*NSPM)
            elseif( iav .eq. 7 ) then
              c=cdat2(NSPM+1:2*NSPM)+cdat2(2*NSPM+1:3*NSPM)
            elseif( iav .eq. 8 ) then
              c=cdat2(1:NSPM)+cdat2(NSPM+1:2*NSPM)+cdat2(2*NSPM+1:3*NSPM)
            endif

! Estimate final frequency error and carrier phase. 
            cca=sum(c(1:1+41)*conjg(cb))
            phase0=atan2(imag(cca),real(cca))

            do ipha=1,3
              if( ipha.eq.2 ) phase0=phase0-20*pi/180.0
              if( ipha.eq.3 ) phase0=phase0+20*pi/180.0

! Remove phase error - want constellation rotated so that sample points lie on I/Q axes
              cfac=cmplx(cos(phase0),sin(phase0))
              c=c*conjg(cfac)

              if( nmatchedfilter .eq. 0 ) then
! sample to get softsamples
                do i=1, 16 
                  softbits(2*i-1)=imag(c(1+(i-1)*12))
                  softbits(2*i)=real(c(7+(i-1)*12))  
                enddo
              else
! matched filter - 
                softbits(1)=sum(imag(c(1:6))*pp(7:12))+sum(imag(c(NSPM-5:NSPM))*pp(1:6))
                softbits(2)=sum(real(c(1:12))*pp)
                do i=2,16
                  softbits(2*i-1)=sum(imag(c(1+(i-1)*12-6:1+(i-1)*12+5))*pp)
                  softbits(2*i)=sum(real(c(7+(i-1)*12-6:7+(i-1)*12+5))*pp)
                enddo
              endif

! sync word hard error weight is a good discriminator for 
! frames that have reasonable probability of decoding
              hardbits=0
              do i=1, 32 
                if( softbits(i) .ge. 0.0 ) then
                  hardbits(i)=1
                endif
              enddo
              nbadsync1=(8-sum( (2*hardbits(1:8)-1)*s8r ) )/2
              nbadsync=nbadsync1
              if( nbadsync .gt. 3 ) cycle

! normalize the softsymbols before submitting to decoder
              sav=sum(softbits)/32
              s2av=sum(softbits*softbits)/32
              ssig=sqrt(s2av-sav*sav)
              softbits=softbits/ssig
            
              if( qsocontext ) then
            ! search 32 likely messages only, using correlation discrepancy 
                cd=1e6
                ihammd=99
                do i=0,31
                  ncw=ig24(likelymessages(i))
                  cd(i)=0.0
                  ihammd(i)=0
                  do ii=1,24
                    ib=iand(1,ishft(ncw,1-ii))
                    ib=2*ib-1 
                    if( ib*softbits(ii+8) .lt. 0 ) cd(i)=cd(i)+abs(softbits(ii+8))
                    if( ib*(2*hardbits(ii+8)-1) .lt. 0 ) ihammd(i)=ihammd(i)+1
                  enddo
                enddo
              else
            ! exhaustive search decoder, using correlation discrepancy 
                cd=1e6
                ihammd=99
                do i=0,4096-1
                  ncw=ig24(i)
                  cd(i)=0.0
                  ihammd(i)=0
                  do ii=1,24
                    ib=iand(1,ishft(ncw,1-ii))
                    ib=2*ib-1 
                    if( ib*softbits(ii+8) .lt. 0 ) cd(i)=cd(i)+abs(softbits(ii+8))
                    if( ib*(2*hardbits(ii+8)-1) .lt. 0 ) ihammd(i)=ihammd(i)+1
                  enddo
                enddo
              endif

              cdm=minval(cd)
              iloc=minloc(cd)
              imsg=iloc(1)-1
              cd(imsg)=1e6
              cdm2=minval(cd)
              iloc=minloc(cd)
              imsg2=iloc(1)-1
              cdrat=cdm2/(cdm+0.001)
!             if( cdrat .gt. cdratbest ) then
              if( cdm .lt. cdbest ) then
                cdratbest = cdrat
                cdbest = cdm
                imsgbest = imsg
                iavbest = iav
                ipbest  = ip
                ipkbest = ipk   
                idfbest = idf
                idbest = id
                iphabest = ipha
                nbadsyncbest = nbadsync
                if( ( ihammd(imsgbest)+nbadsyncbest  .le. 4 )  .and. ( (cdratbest .gt. 100.0) .and. (cdbest .le. 0.05) ) ) goto 999
              endif
            enddo   ! phase loop
          enddo   ! frame averaging loop
        enddo   ! frequency dithering loop
      enddo   ! sample-time dither loop
    enddo   ! peak loop

!    write(78,1001) nutc,t0,nsnr,ic,ipk,is,idf,iav,deltaf,fest,ferr,ferr2,ffin,bba,bbp,nbadsync, &
!             phase0,msgreceived
!      call flush(78)
!1001 format(i6.6,f8.2,i5,i5,i5,i5,i5,i5,f8.2,f8.2,f8.2,f8.2,f8.2,f10.2,f8.2,i5,f8.2,2x,a22)
  enddo
999 continue
  msgreceived=' '
  if( imsgbest .gt. 0 ) then
    if( ( ihammd(imsgbest)+nbadsyncbest .le. 4 ) .and. (cdratbest .gt. 50.0) .and. (cdbest .le. 0.05) ) then
      if( qsocontext ) then
        nrxrpt=iand(likelymessages(imsgbest),31)
        nrxhash=(likelymessages(imsgbest)-nrxrpt)/32
        imessage=likelymessages(imsgbest)
      else
        nrxrpt=iand(imsgbest,31)
        nrxhash=(imsgbest-nrxrpt)/32
        imessage=imsgbest
      endif

! See if this message has a hash that is expected for a message sent to mycall by partnercall
      hashmsg=trim(mycall)//' '//trim(partnercall)//' '//rpt(nrxrpt)
      call fmtmsg(hashmsg,iz)
      call hash(hashmsg,22,ihash)
      ihash=iand(ihash,127)
      if( nrxhash .eq. ihash ) then
        nmessages=1
        write(msgreceived,'(a1,a,1x,a,a1,1x,a4)') "<",trim(mycall),trim(partnercall),">",rpt(nrxrpt)    
        write(lines(nmessages),1020) nutc,nsnr,t0,nint(fest),msgreceived
1020    format(i6.6,i4,f5.1,i5,' & ',a22)

!       write(*,1022) nutc,ipbest,times(ipbest),snrs(ipbest),fest,nrxrpt,nrxhash, &
!                    rpt(nrxrpt),imessage,ig24(imessage),ihammd(imsgbest), &
!                    cdbest,cdratbest,nbadsyncbest,ipkbest,idbest,idfbest,iavbest,iphabest
      endif
    endif
  endif
!1022 format(i4.4,2x,i4,f8.3,f8.2,f8.2,i6,i6,a6,i8,i10,i4,f8.2,f8.2,i5,i5,i5,i5,i5,i5) 
  return
end subroutine detectmsk32
