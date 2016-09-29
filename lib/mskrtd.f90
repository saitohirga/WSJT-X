subroutine mskrtd(id2,nutc0,tsec,ntol,nrxfreq,ndepth,line)

! Real-time decoder for MSK144.  
! Analysis block size = NZ = 7168 samples, t_block = 0.597333 s 
! Called from hspec() at half-block increments, about 0.3 s

  parameter (NZ=7168)                !Block size
  parameter (NSPM=864)               !Number of samples per message frame
  parameter (NFFT1=8192)             !FFT size for making analytic signal
  parameter (NPATTERNS=4)            !Number of frame averaging patterns to try

  character*3 decsym                 !"&" for mskspd or "^" for long averages
  character*22 msgreceived           !Decoded message
  character*22 msglast               !!! temporary - used for dupechecking
  character*80 line                  !Formatted line with UTC dB T Freq Msg

  complex cdat(NFFT1)                !Analytic signal
  complex c(NSPM)                    !Coherently averaged complex data
  complex ct(NSPM)

  integer*2 id2(NZ)                  !Raw 16-bit data
  integer iavmask(8)
  integer iavpatterns(8,NPATTERNS)
  integer npkloc(10)
  integer nav(6)

  real d(NFFT1)
  real pow(8)
  real xmc(NPATTERNS)
  logical first
  data first/.true./
  data nav/1,2,3,5,7,9/
  data iavpatterns/ &
       1,1,1,1,0,0,0,0, &
       0,0,1,1,1,1,0,0, &
       1,1,1,1,1,0,0,0, &
       1,1,1,1,1,1,1,0/
  data xmc/2.0,4.5,2.5,3.5/ !Used to label decode with time at center of averaging mask

  save first,tsec0,nutc00,pnoise,nsnrlast,msglast

  if(first) then
     tsec0=tsec
     nutc00=nutc0
     pnoise=-1.0
     first=.false.
  endif

  fc=nrxfreq

!!! Dupe checking should probaby be moved to mainwindow.cpp
  if(nutc00.ne.nutc0 .or. tsec.lt.tsec0) then ! reset dupe checker
    msglast='                      '
    nsnrlast=-99
    nutc00=nutc0
  endif
  
  tframe=float(NSPM)/12000.0 
  line=char(0)
  msgreceived='                      '
  max_iterations=10
  niterations=0
  d(1:NZ)=id2
  rms=sqrt(sum(d(1:NZ)*d(1:NZ))/NZ)
  if(rms.lt.1.0) go to 999
  fac=1.0/rms
  d(1:NZ)=fac*d(1:NZ)
  d(NZ+1:NFFT1)=0.
  call analytic(d,NZ,NFFT1,cdat)      !Convert to analytic signal and filter

! Calculate average power for each frame and for the entire block.
! If decode is successful, largest power will be taken as signal+noise.
! If no decode, entire-block average will be used to update noise estimate.
  pmax=-99
  do i=1,8 
    ib=(i-1)*NSPM+1
    ie=ib+NSPM-1
    pow(i)=real(dot_product(cdat(ib:ie),cdat(ib:ie)))*rms**2
    if( pow(i) .gt. pmax ) then
      pmax=pow(i)
    endif
  enddo
  pavg=sum(pow)/8.0

! Short ping decoder uses squared-signal spectrum to determine where to
! center a 3-frame analysis window and attempts to decode each of the 
! 3 frames along with 2- and 3-frame averages. 
  np=8*NSPM
  call msk144spd(cdat,np,ntol,nsuccess,msgreceived,fc,fest,tdec)
  if( nsuccess .eq. 1 ) then
    tdec=tsec+tdec
    decsym=' & '
    goto 900
  endif 

! If short ping decoder doesn't find a decode, 
! Fast - short ping decoder only. 
! Normal - try 4-frame averages
! Deep - try 4-, 5- and 7-frame averages. 
  npat=NPATTERNS
  if( ndepth .eq. 1 ) npat=0
  if( ndepth .eq. 2 ) npat=2
  do iavg=1,npat
     iavmask=iavpatterns(1:8,iavg)
     navg=sum(iavmask)
     deltaf=7.0/real(navg)  ! search increment for frequency sync
     npeaks=2
     call msk144sync(cdat(1:8*NSPM),8,ntol,deltaf,iavmask,npeaks,fc,fest,npkloc,nsyncsuccess,c)
     if( nsyncsuccess .eq. 0 ) cycle

     do ipk=1,npeaks
        do is=1,3
           ic0=npkloc(ipk)
           if(is.eq.2) ic0=max(1,ic0-1)
           if(is.eq.3) ic0=min(NSPM,ic0+1)
           ct=cshift(c,ic0-1)

           call msk144decodeframe(ct,msgreceived,ndecodesuccess)

           if(ndecodesuccess .gt. 0) then
             tdec=tsec+xmc(iavg)*tframe
             decsym=' ^ '
             goto 900
           endif
        enddo                         !Slicer dither
     enddo                            !Peak loop 
  enddo

  msgreceived=' '

! no decode - update noise level used for calculating displayed snr.  
  if( pnoise .lt. 0 ) then         ! initialize noise level
     pnoise=pavg
  elseif( pavg .gt. pnoise ) then  ! noise level is slow to rise
     pnoise=0.9*pnoise+0.1*pavg
  elseif( pavg .lt. pnoise ) then  ! and quick to fall
     pnoise=pavg
  endif
  go to 999

900 continue
! successful decode - estimate snr  !!! noise estimate needs work
  if( pnoise .gt. 0.0 ) then
    snr0=10.0*log10(pmax/pnoise-1.0)
  else
    snr0=0.0
  endif
  nsnr=nint(snr0)

!!!! Temporary - dupe check. Only print if new message, or higher snr.
  if(msgreceived.ne.msglast .or. nsnr.gt.nsnrlast .or. tsec.lt.tsec0) then
     msglast=msgreceived
     nsnrlast=nsnr
     if( nsnr .lt. -8 ) nsnr=-8
     if( nsnr .gt. 24 ) nsnr=24
     write(line,1020) nutc0,nsnr,tdec,nint(fest),decsym,msgreceived,char(0)
1020 format(i6.6,i4,f5.1,i5,a3,a22,a1)
  endif

999 tsec0=tsec

  return
end subroutine mskrtd

