program msk144sd
!
! A simple decoder for slow msk144.
! Can be used as a (slow) brute-force multi-decoder by looping
! over a set of carrier frequencies.
!
  use options
  use timer_module, only: timer
  use timer_impl, only: init_timer
  use readwav

  parameter (NRECENT=10)
  parameter (NSPM=864)
  parameter (NPATTERNS=4)

  character ch
  character*80 line
  character*500 infile
  character*12 mycall,hiscall
  character*6 mygrid
  character(len=500) optarg
  character*22 msgreceived
  character*12 recent_calls(NRECENT)

  complex cdat(30*375)
  complex c(NSPM)
  complex ct(NSPM)

  real softbits(144)
  real xmc(NPATTERNS)

  logical :: display_help=.false.

  type(wav_header) :: wav

  integer iavmask(8)
  integer iavpatterns(8,NPATTERNS)
  integer npkloc(10)

  integer*2 id2(30*12000)
  integer*2 ichunk(7*1024)
  
  data iavpatterns/ &
       1,1,1,1,0,0,0,0, &
       0,1,1,1,1,0,0,0, &
       0,0,1,1,1,1,0,0, &
       1,1,1,1,1,1,0,0/
  data xmc/2.0,4.5,2.5,3.0/

  type (option) :: long_options(2) = [ &
       option ('frequency',.true.,'f','rxfreq',''), &
       option ('help',.false.,'h','Display this help message','') &
       ]
  t0=0.0
  ntol=100
  nrxfreq=1500
 
  do
     call getopt('f:h',long_options,ch,optarg,narglen,nstat,noffset,nremain,.true.)
     if( nstat .ne. 0 ) then
        exit
     end if
     select case (ch)
     case ('f')
        read (optarg(:narglen), *) nrxfreq
     case ('h')
        display_help = .true.
     end select
  end do

  if(display_help .or. nstat.lt.0 .or. nremain.lt.1) then
     print *, ''
     print *, 'Usage: msk144sd [OPTIONS] file1 [file2 ...]'
     print *, ''
     print *, '       decode pre-recorded .WAV file(s)'
     print *, ''
     print *, 'OPTIONS:'
     do i = 1, size (long_options)
        call long_options(i) % print (6)
     end do
     go to 999
  endif

  call init_timer ('timer.out')
  call timer('msk144  ',0)
  ndecoded=0
  do ifile=noffset+1,noffset+nremain
     call get_command_argument(ifile,optarg,narglen)
     infile=optarg(:narglen)
     call timer('read    ',0)
     call wav%read (infile)
     i1=index(infile,'.wav')
     if( i1 .eq. 0 ) i1=index(infile,'.WAV')
     read(infile(i1-6:i1-1),*,err=998) nutc
     inquire(FILE=infile,SIZE=isize)
     npts=min((isize-216)/2,360000)
     read(unit=wav%lun) id2(1:npts)
     close(unit=wav%lun)
     call timer('read    ',1)

!   do if=1,89  ! brute force multi-decoder
     fo=nrxfreq
!     fo=(if-1)*25.0+300.0
     call msksddc(id2,npts,fo,cdat)
     np=npts/32
     ntol=200  ! actual ntol is ntol/32=6.25 Hz. Detection window is 12.5 Hz wide
     fc=1500.0
     call msk144spd(cdat,np,ntol,ndecodesuccess,msgreceived,fc,fest,tdec,navg,ct, &
                    softbits,recent_calls,nrecent)
     nsnr=0  ! need an snr estimate
     if( ndecodesuccess .eq. 1 ) then
       fest=fo+fest-fc   ! fudging because spd thinks input signal is at 1500 Hz
       goto 900 
     endif
! If short ping decoder doesn't find a decode 
     npat=NPATTERNS
     do iavg=1,npat
       iavmask=iavpatterns(1:8,iavg)
       navg=sum(iavmask)
       deltaf=4.0/real(navg)  ! search increment for frequency sync
       npeaks=4
       ntol=200
       fc=1500.0
       call msk144sync(cdat(1:6*NSPM),6,ntol,deltaf,iavmask,npeaks,fc,           &
          fest,npkloc,nsyncsuccess,xmax,c)
       if( nsyncsuccess .eq. 0 ) cycle

       do ipk=1,npeaks
         do is=1,3   
           ic0=npkloc(ipk)
           if(is.eq.2) ic0=max(1,ic0-1)
           if(is.eq.3) ic0=min(NSPM,ic0+1)
           ct=cshift(c,ic0-1)
           call msk144decodeframe(ct,softbits,msgreceived,ndecodesuccess,      &
                                  recent_calls,nrecent)
           if(ndecodesuccess .gt. 0) then
              tdec=tsec+xmc(iavg)*tframe
              fest=fo+(fest-fc)/32.0   
              goto 900
           endif
         enddo                         !Slicer dither
       enddo                            !Peak loop 
     enddo

!   enddo
900 continue
    if( ndecodesuccess .gt. 0 ) then
       write(*,1020) nutc,nsnr,tdec,nint(fest),' % ',msgreceived,navg
1020   format(i6.6,i4,f5.1,i5,a3,a22,i4)
    endif
  enddo

  call timer('msk144  ',1)
  call timer('msk144  ',101)
  go to 999

998 print*,'Cannot read from file:'
  print*,infile

999 continue
end program msk144sd

subroutine msksddc(id2,npts,fc,cdat)

! The msk144 detector/demodulator/decoder will decode signals
! with carrier frequency, fc, in the range fN/4 +/- 0.03333*fN. 
!
! For slow MSK144 with nslow=32: 
!  fs=12000/32=375 Hz, fN=187.5 Hz
!
! This routine accepts input samples with fs=12000 Hz. It
! downconverts and decimates by 32 to center a signal with input carrier
! frequency fc at new carrier frequency 1500/32=46.875 Hz.
! The analytic signal is returned.
 
  parameter (NFFT1=30*12000,NFFT2=30*375)
  integer*2 id2(npts)
  complex cx(0:NFFT1)
  complex cdat(30*375)

  dt=1.0/12000.0
  df=1.0/(NFFT1*dt)
  icenter=int(fc/df+0.5)
  i46p875=int(46.875/df+0.5)
  ishift=icenter-i46p875
  cx=cmplx(0.0,0.0)
  cx(1:npts)=id2
  call four2a(cx,NFFT1,1,-1,1)
  cx=cshift(cx,ishift)
  cx(1)=0.5*cx(1)
  cx(2*i46p875+1:)=cmplx(0.0,0.0)
  call four2a(cx,NFFT2,1,1,1)
  cdat(1:npts/32)=cx(0:npts/32-1)/NFFT1
  return

end subroutine msksddc

