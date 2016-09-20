subroutine mskrtd(id2,nutc0,tsec,ntol,line)

! Real-time decoder for MSK144.  
! Analysis block size = NZ = 7168 samples, t_block = 0.597333 s 
! Called from hspec() at half-block increments, about 0.3 s

  parameter (NZ=7168)                !Block size
  parameter (NSPM=864)               !Number of samples per message frame
  parameter (NFFT1=8192)             !FFT size for making analytic signal
  parameter (NAVGMAX=7)              !Coherently average up to 7 frames
  parameter (NPTSMAX=7*NSPM)         !Max points analyzed at once

  integer*2 id2(NZ)                  !Raw 16-bit data
  character*22 msgreceived           !Decoded message
  character*80 line                  !Formatted line with UTC dB T Freq Msg

  complex cdat(NFFT1)                !Analytic signal
  complex cdat2(NFFT1)               !Signal shifted to baseband
  complex c(NSPM)                    !Coherently averaged complex data
  complex ct(NSPM)
  complex ct2(2*NSPM)
  complex cs(NSPM)
  complex cb(42)                     !Complex waveform for sync word 
  complex cc(0:NSPM-1)

!  integer*8 count0,count1,count2,count3,clkfreq
  integer s8(8)
  integer iloc(1)
  integer ipeaks(10)
  integer nav(6)

  real cbi(42),cbq(42)
  real d(NFFT1)
  real xcc(0:NSPM-1)
  real xccs(0:NSPM-1)
  real pp(12)                        !Half-sine pulse shape
  logical first
  data first/.true./
  data s8/0,1,1,1,0,0,1,0/
  data nav/1,2,3,5,7,9/
  save first,cb,fs,pi,twopi,dt,s8,pp,t03,t12,nutc00

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
     nutc00=-1
  endif

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
  
  nmessages=0
  line=' '
  nshort=0
  npts=7168
  nsnr=-4                             !### Temporary ###

  do iavg=1,5
     navg=nav(iavg)
     ndf=nint(7.0/navg) + 1
     xmax=0.0
     bestf=0.0
!     call system_clock(count1,clkfreq)
     do ifr=-ntol,ntol,ndf            !Find freq that maximizes sync
        ferr=ifr
        call tweak1(cdat,NPTS,-(1500+ferr),cdat2)
        c=0
        do i=1,navg
           ib=(i-1)*NSPM+1
           ie=ib+NSPM-1
           c(1:NSPM)=c(1:NSPM)+cdat2(ib:ie)
        enddo

        cc=0
        ct2(1:NSPM)=c
        ct2(NSPM+1:2*NSPM)=c
        do ish=0,NSPM-1
           cc(ish)=dot_product(ct2(1+ish:42+ish)+ct2(336+ish:377+ish),cb(1:42))
        enddo

        xcc=abs(cc)
        xb=maxval(xcc)/(48.0*sqrt(float(navg)))
        if(xb.gt.xmax) then
           xmax=xb
           bestf=ferr
           cs=c
           xccs=xcc
        endif
     enddo
!     call system_clock(count2,clkfreq)

     fest=1500+bestf
     c=cs
     xcc=xccs

! Find 2 largest peaks
     do ipk=1,2
        iloc=maxloc(xcc)
        ic2=iloc(1)
        ipeaks(ipk)=ic2
        xcc(max(0,ic2-7):min(NSPM-1,ic2+7))=0.0
     enddo

     do ipk=1,2
        do is=1,3
           ic0=ipeaks(ipk)
           if(is.eq.2) ic0=max(1,ic0-1)
           if(is.eq.3) ic0=min(NSPM,ic0+1)
           ct=cshift(c,ic0-1)

           call msk144decodeframe(ct,msgreceived,nsuccess)

           if(nsuccess .gt. 0) then
write(*,*) nsuccess,msgreceived
             write(line,1020) nutc0,nsnr,tsec,nint(fest),msgreceived,char(0)
1020         format(i6.6,i4,f5.1,i5,' ^ ',a22,a1)
             goto 999
           endif
        enddo                         !Slicer dither
     enddo                            !Peak loop 
  enddo

  msgreceived=' '
  ndither=-98   
999 continue

!  call system_clock(count3,clkfreq)
!  t12=t12 + float(count2-count1)/clkfreq
!  t03=t03 + float(count3-count0)/clkfreq
!  if(navg.gt.7) navg=0
!  write(*,3002)  nutc0,tsec,t12,t03,xmax,nint(bestf),navg,           &
!       nbadsync,niterations,ipk,is,msgreceived(1:19)
!  write(62,3002) nutc0,tsec,t12,t03,xmax,nint(bestf),navg,           &
!       nbadsync,niterations,ipk,is,msgreceived(1:19)
!3002 format(i6,f6.2,2f7.2,f6.2,i5,5i3,1x,a19)

  return
end subroutine mskrtd
