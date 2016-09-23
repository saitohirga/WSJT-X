subroutine mskrtd(id2,nutc0,tsec,ntol,line)

! Real-time decoder for MSK144.  
! Analysis block size = NZ = 7168 samples, t_block = 0.597333 s 
! Called from hspec() at half-block increments, about 0.3 s

  parameter (NZ=7168)                !Block size
  parameter (NSPM=864)               !Number of samples per message frame
  parameter (NFFT1=8192)             !FFT size for making analytic signal
  parameter (NAVGMAX=7)              !Coherently average up to 7 frames
  parameter (NPTSMAX=7*NSPM)         !Max points analyzed at once
  parameter (NPATTERNS=4)            !Number of frame averaging patterns to try

  character*3 decsym                 !"&" for mskspd or "^" for long averages
  character*22 msgreceived           !Decoded message
  character*22 msglast               !!! temporary - used for dupechecking
  character*80 line                  !Formatted line with UTC dB T Freq Msg

  complex cdat(NFFT1)                !Analytic signal
  complex c(NSPM)                    !Coherently averaged complex data
  complex ct(NSPM)
  complex cb(42)                     !Complex waveform for sync word 

!  integer*8 count0,count1,count2,count3,clkfreq
  integer*2 id2(NZ)                  !Raw 16-bit data
  integer iavmask(8)
  integer iavpatterns(8,NPATTERNS)
  integer s8(8)
  integer npkloc(10)
  integer nav(6)

  real cbi(42),cbq(42)
  real d(NFFT1)
  real pp(12)                        !Half-sine pulse shape
  real pow(7)
  real xmc(NPATTERNS)
  logical first
  data first/.true./
  data s8/0,1,1,1,0,0,1,0/
  data nav/1,2,3,5,7,9/
  data iavpatterns/ &
       1,1,1,1,0,0,0,0, &
       0,0,1,1,1,1,0,0, &
       1,1,1,1,1,0,0,0, &
       1,1,1,1,1,1,1,0/
  data xmc/2.0,4.5,2.5,3.5/ !Used to label decode with time at center of averaging mask

  save first,cb,fs,pi,twopi,dt,s8,pp,t03,t12,nutc00,pnoise,nsnrlast,msglast

!  call system_clock(count0,clkfreq)
  if(first) then
     pi=4.0*atan(1.0)
     twopi=8.0*atan(1.0)
     fs=12000.0
     dt=1.0/fs

     do i=1,12                       !Define half-sine pulse
       angle=(i-1)*pi/12.0
       pp(i)=sin(angle)
     enddo

! Define the sync word waveforms
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
     t03=0.0
     t12=0.0
     nutc00=nutc0
     pnoise=-1.0
  endif

  fc=1500.0   !!! This will eventually come from the Rx Freq GUI box.

!!! Dupe checking should probaby be moved to mainwindow.cpp
  if( nutc00 .ne. nutc0 ) then ! reset dupe checker
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
  if(rms.lt.1.0) return
  fac=1.0/rms
  d(1:NZ)=fac*d(1:NZ)
  d(NZ+1:NFFT1)=0.
  call analytic(d,NZ,NFFT1,cdat)      !Convert to analytic signal and filter

  pmax=-99
  do i=1,7 
    ib=(i-1)*NSPM+1
    ie=ib+NSPM-1
    pow(i)=dot_product(cdat(ib:ie),cdat(ib:ie))*rms**2
    if( pow(i) .gt. pmax ) then
      pmax=pow(i)
    endif
  enddo
  pavg=sum(pow)/7.0
  
  np=8*NSPM

  call msk144spd(cdat,np,ntol,nsuccess,msgreceived,fc,fest,tdec)

  if( nsuccess .eq. 1 ) then
    tdec=tsec+tdec
    decsym=' & '
    goto 999
  endif 
    
  do iavg=1,NPATTERNS
     iavmask=iavpatterns(1:8,iavg)
     navg=sum(iavmask)
     ndf=nint(7.0/navg) 
     npeaks=2
     call msk144sync(cdat(1:8*NSPM),8,ntol,ndf,iavmask,npeaks,fc,fest,npkloc,nsyncsuccess,c)
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
             goto 999
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

  return

999 continue

! successful decode - estimate snr  !!! noise estimate needs work
  if( pnoise .gt. 0.0 ) then
    snr0=10.0*log10(pmax/pnoise-1.0)
  else
    snr0=0.0
  endif
  nsnr=nint(snr0)

!!!! Temporary - dupe check. Only print if new message, or higher snr.
  if( msgreceived .eq. msglast .and. nsnr .le. nsnrlast ) return

  msglast=msgreceived
  nsnrlast=nsnr
  if( nsnr .lt. -8 ) nsnr=-8
  if( nsnr .gt. 24 ) nsnr=24
  write(line,1020) nutc0,nsnr,tdec,nint(fest),decsym,msgreceived,char(0)
1020 format(i6.6,i4,f5.1,i5,a3,a22,a1)
  return
end subroutine mskrtd

