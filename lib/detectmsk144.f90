subroutine detectmsk144(cbig,n,pchk_file,lines,nmessages,nutc)
  use timer_module, only: timer

  parameter (NSPM=864, NPTS=3*NSPM, MAXSTEPS=1500)
  character*22 msgreceived,allmessages(20)
  character*80 lines(100)
  character*512 pchk_file,gen_file
  complex cbig(n)
  complex cdat(NPTS)                    !Analytic signal
  complex cdat2(NPTS)
  complex c(NSPM)
  complex ctmp(6000)                  
  complex cb(42)                        !Complex waveform for sync word 
  complex cfac,cca,ccb
  complex cc(NPTS)
  complex cc1(NPTS)
  complex cc2(NPTS)
  complex bb(6)
  integer s8(8),hardbits(144)
  integer, dimension(1) :: iloc
  integer*1 decoded(80)   
  integer indices(MAXSTEPS)
  integer ipeaks(10)
  logical ismask(6000)
  real cbi(42),cbq(42)
  real detmet(-2:MAXSTEPS+3)
  real detfer(MAXSTEPS)
  real tonespec(6000)
  real rcw(12)
  real dd(NPTS)
  real ferrs(20)
  real pp(12)                          !Half-sine pulse shape
  real snrs(20)
  real times(20)
  real*8 dt, df, fs, pi, twopi
  real softbits(144)
  real*8 unscrambledsoftbits(128)
  real lratio(128)
  logical first
  data first/.true./
  data s8/0,1,1,1,0,0,1,0/
  save df,first,cb,fs,nfft,pi,twopi,dt,s8,rcw,pp

  if(first) then
     nmatchedfilter=1
     i=index(pchk_file,".pchk")
     gen_file=pchk_file(1:i-1)//".gen"
     call init_ldpc(trim(pchk_file)//char(0),trim(gen_file)//char(0))
! define half-sine pulse and raised-cosine edge window
     pi=4d0*datan(1d0)
     twopi=8d0*datan(1d0)
     fs=12000.0
     dt=1.0/fs
     nfft=6000      !using a zero-padded fft to get 2 Hz bins
     df=fs/nfft

     do i=1,12
       angle=(i-1)*pi/12.0
       pp(i)=sin(angle)
       rcw(i)=(1-cos(angle))/2
     enddo

! define the sync word waveform
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

     first=.false.
  endif

  ! fill the detmet, detferr arrays
  nstep=(n-NSPM)/256
  detmet=0
  do istp=1,nstep
    ns=1+256*(istp-1)
    ne=ns+NPTS-1
    if( ne .gt. n ) exit
    cdat=cbig(ns:ne)

! Coarse carrier frequency sync - seek tones at 2000 Hz and 4000 Hz in 
! squared signal spectrum.
! search range for coarse frequency error is +/- 100 Hz

    ctmp=cmplx(0.0,0.0)
    ctmp(1:NPTS)=cdat**2
    ctmp(1:12)=ctmp(1:12)*rcw
    ctmp(NPTS-11:NPTS)=ctmp(NPTS-11:NPTS)*rcw(12:1:-1)
    call four2a(ctmp,nfft,1,-1,1)
    tonespec=abs(ctmp)**2

    ismask=.false.
    ismask(1901:2101)=.true.  ! high tone search window
    iloc=maxloc(tonespec,ismask)
    ihpk=iloc(1)
    ah=tonespec(ihpk)
    ismask=.false.
    ismask(901:1101)=.true.   ! window for low tone
    iloc=maxloc(tonespec,ismask)
    ilpk=iloc(1)
    al=tonespec(ilpk)
    fdiff=(ihpk-ilpk)*df
    ferrh=(ihpk-2001)*df/2.0
    ferrl=(ilpk-1001)*df/2.0
    if( abs(fdiff-2000) .le. 16.0 ) then
      if( ah .ge. al ) then
        ferr=ferrh
      else
        ferr=ferrl
      endif
    else
      ferr=-999.99
    endif
    detmet(istp)=ah+al
    detfer(istp)=ferr
  enddo  ! end of detection-metric and frequency error estimation loop

  call indexx(detmet(1:nstep),nstep,indices) !find median of detection metric vector
  xmed=detmet(indices(nstep/2))
  detmet=detmet/xmed ! noise floor of detection metric is 1.0

  ndet=0

  do ip=1,20 ! use something like the "clean" algorithm to find candidates
    iloc=maxloc(detmet(1:nstep))
    il=iloc(1)
    if( (detmet(il) .lt. 1.5) .or. (abs(detfer(il)) .gt. 100.0) ) cycle 
    ndet=ndet+1
    times(ndet)=((il-1)*256+NPTS/2)*dt
    ferrs(ndet)=detfer(il)
    snrs(ndet)=10.0*log10(detmet(il))/2-5.0 !/2 because detmet is a 4th order moment
    detmet(il-3:il+3)=0.0
  enddo

  nmessages=0
  allmessages=char(0)
  lines=char(0)

  do ip=1,ndet  !run through the candidates and try to sync/demod/decode
    imid=times(ip)*fs
    t0=times(ip)
    cdat=cbig(imid-NPTS/2+1:imid+NPTS/2)
    ferr=ferrs(ip)
    nsnr=snrs(ip)

! remove coarse freq error - should now be within a few Hz
    call tweak1(cdat,NPTS,-(1500+ferr),cdat)

! attempt frame synchronization
! correlate with sync word waveforms
    cc=0
    cc1=0
    cc2=0
    do i=1,NPTS-(56*6+41)
      cc1(i)=sum(cdat(i:i+41)*conjg(cb))
      cc2(i)=sum(cdat(i+56*6:i+56*6+41)*conjg(cb))
    enddo
    cc=cc1+cc2
    dd=abs(cc1)*abs(cc2)

! Find 5 largest peaks
    do ipk=1,5
      iloc=maxloc(abs(cc))
      ic1=iloc(1)
      iloc=maxloc(dd)
      ic2=iloc(1)
      ipeaks(ipk)=ic2
      dd(max(1,ic2-7):min(NPTS-56*6-41,ic2+7))=0.0
    enddo

    do ipk=1,5

! we want ic to be the index of the first sample of the frame
      ic0=ipeaks(ipk)

! fine adjustment of sync index
      do i=1,6
        if( ic0+11+NSPM .le. NPTS ) then
          bb(i) = sum( ( cdat(ic0+i-1+6:ic0+i-1+6+NSPM:6) * conjg( cdat(ic0+i-1:ic0+i-1+NSPM:6) ) )*2 )
        else
          bb(i) = sum( ( cdat(ic0+i-1+6:NPTS:6) * conjg( cdat(ic0+i-1:NPTS-6:6) ) )*2 )
        endif
      enddo
      iloc=maxloc(abs(bb))
      ibb=iloc(1)
      bba=abs(bb(ibb))
      if( ibb .le. 3 ) ibb=ibb-1
      if( ibb .gt. 3 ) ibb=ibb-7

      do id=1,3     ! slicer dither. bb is very good - may be able to remove this.
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

        do idf=0,10   ! frequency jitter
          if( idf .eq. 0 ) then
            deltaf=0.0
          elseif( mod(idf,2) .eq. 0 ) then
            deltaf=idf/2.0
          else
            deltaf=-(idf+1)/2.0
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
            if( nbadsync .gt. 6 ) cycle

! normalize the softsymbols before submitting to decoder
            sav=sum(softbits)/144
            s2av=sum(softbits*softbits)/144
            ssig=sqrt(s2av-sav*sav)
            softbits=softbits/ssig

            sigma=0.65
            lratio(1:48)=softbits(9:9+47)
            lratio(49:128)=softbits(65:65+80-1)
            lratio=exp(2.0*lratio/(sigma*sigma))
  
            unscrambledsoftbits(1:127:2)=lratio(1:64)
            unscrambledsoftbits(2:128:2)=lratio(65:128)

            max_iterations=20
            max_dither=1
            call ldpc_decode(unscrambledsoftbits, decoded, &
                           max_iterations, niterations, max_dither, ndither)

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
1020              format(i6.6,i4,f5.1,i5,' & ',a22)
                endif
                goto 999
              else
                msgreceived=' '
                ndither=-99             ! -99 is bad hash flag
!                write(78,1001) nutc,t0,nsnr,ipk,is,idf,iav,deltaf,fest,ffin,nbadsync1,nbadsync2, &
!                             phase0,niterations,ndither,msgreceived
              endif
            endif
          enddo ! frame averaging loop
        enddo  ! frequency dithering loop
      enddo   ! sample-time dither loop
    enddo     ! peak loop - could be made more efficient by working harder to find good peaks

    msgreceived=' '
    ndither=-98   
999 continue
!    write(78,1001) nutc,t0,nsnr,ipk,is,idf,iav,deltaf,fest,ffin,nbadsync1,nbadsync2, &
!               phase0,niterations,ndither,msgreceived
!1001 format(i6.6,f8.2,i4,i4,i4,i4,i4,f8.2,f8.2,f8.2,i4,i4,f8.2,i5,i5,2x,a22)
  enddo
  return
end subroutine detectmsk144
