subroutine q65_avg(nutc,ntrperiod,mode_q65,LL,nfqso,ntol,lclearave,   &
     baud,nsubmode,ibwa,ibwb,codewords,ncw,xdt,f0,snr1,s3)

! Accumulate Q65 spectra s3(LL,63) and associated parameters for
! message averaging.

  use q65
  use packjt77
  parameter (PLOG_MIN=-240.0)            !List decoding threshold
  character*37 avemsg
  character*1 csync,cused(MAXAVE)
  character*6 cutc
  character*77 c77
  real s3(-64:LL-65,63)                  !Symbol spectra
  real s3prob(0:63,63)                   !Symbol-value probabilities
  integer iused(MAXAVE)
  integer dat4(13)
  integer codewords(63,206)
  logical first,lclearave,unpk77_success
  data first/.true./
  save

  if(first .or. LL.ne.LL0 .or.lclearave) then
     iutc=-1
     iseq=-1
     f0save=0.0
     dtdiff=0.2
     nsave=0
     LL0=LL
     first=.false.
     if(allocated(s3save)) deallocate(s3save)
     if(allocated(s3avg)) deallocate(s3avg)
     allocate(s3save(-64:LL-65,63,MAXAVE))
     allocate(s3avg(-64:LL-65,63))
     s3save=0.
     s3avg=0.
  endif

  if(ntrperiod.eq.15) then
     dtdiff=0.038
  else if(ntrperiod.eq.30) then
     dtdiff=0.08
  else if(ntrperiod.eq.60) then
     dtdiff=0.16
  else if(ntrperiod.eq.120) then
     dtdiff=0.4
  else if(ntrperiod.eq.300) then
     dtdiff=0.9
  endif

  do i=1,MAXAVE       !Don't save info more than once for same UTC and freq
     if(nutc.eq.iutc(i) .and. abs(nfreq-f0save(i)).le.ntol) go to 10
  enddo

! Save data for message averaging
  nsave=nsave+1
  n=nutc
  if(ntrperiod.ge.60) n=100*n
  write(cutc,'(i6.6)') n
  read(cutc,'(3i2)') ih,im,is
  nsec=3600*ih + 60*im + is
  iseq(nsave)=mod(nsec/ntrperiod,2)         !T/R sequence: 0 (even) or 1 (odd)
  iutc(nsave)=nutc                          !UTC, hhmm or hhmmss
  snr1save(nsave)=snr1                      !SNR from sync
  xdtsave(nsave)=xdt                        !DT
  f0save(nsave)=f0                           !f0
  s3save(:,:,nsave)=s3(:,:)                 !Symbol spectra

10 continue

!10 if(nsave.lt.2) go to 900

  snr1sum=0.
  xdtsum=0.
  fsum=0.
  nsum=0
  s3avg=0.

! Find previously saved spectra that should be averaged with this one
  do i=1,MAXAVE
     cused(i)='.'                                   !Flag for "not used"
     if(iutc(i).lt.0) cycle
     if(iseq(i).ne.iseq(nsave)) cycle               !Sequence must match
!     write(*,3000) i,iseq(i),nutc,iutc(i),xdt-xdtsave(i),f0-f0save(i)
!3000 format(2i2,2i5,2f7.2)
     if(abs(xdt-xdtsave(i)).gt.dtdiff) cycle        !DT must be close
     if(abs(f0-f0save(i)).gt.float(ntol)) cycle   !Freq must match
!     write(*,3001) 'a',i,nsave,iseq(i),snr1,xdt,f0
!3001 format(a1,3i4,3f8.2)
     cused(i)='$'                                   !Flag for "use this one"
     s3avg=s3avg + s3save(:,:,i)                    !Add this spectrum
     snr1sum=snr1sum + snr1save(i)
     xdtsum=xdtsum + xdtsave(i)
     fsum=fsum + f0save(i)
     nsum=nsum+1
     iused(nsum)=i
  enddo
  if(nsum.lt.MAXAVE) iused(nsum+1)=0

! Find averages of snr1, xdt, and f0 used in this decoding attempt.
  snr1ave=0.
  xdtave=0.
  fave=0.
  if(nsum.gt.0) then
     snr1ave=snr1sum/nsum
     xdtave=xdtsum/nsum
     fave=fsum/nsum
  endif

! Write parameters for display to User in the Message Averaging window.
  do i=1,nsave
     if(ntrperiod.le.30) write(14,1000) cused(i),iutc(i),snr1save(i),    &
          xdtsave(i),f0save(i)
1000 format(a1,i7.6,f6.1,f6.2,f7.1)
     if(ntrperiod.ge.60) write(14,1001) cused(i),iutc(i),snr1save(i),    &
          xdtsave(i),f0save(i)
1001 format(a1,i5.4,f6.1,f6.2,f7.1)
  enddo
!  if(nsum.lt.2) go to 900                  !Must have at least 2

! Find rms scatter of DT and f0 values
  sqt=0.
  sqf=0.
  do j=1,MAXAVE
     i=iused(j)
     if(i.eq.0) exit
     csync='*'
     sqt=sqt + (xdtsave(i)-dtave)**2
     sqf=sqf + (f0save(i)-fave)**2
  enddo
  rmst=0.
  rmsf=0.
  if(nsum.ge.2) then
     rmst=sqrt(sqt/(nsum-1))
     rmsf=sqrt(sqf/(nsum-1))
  endif

  s3avg=s3avg/nsum
  nFadingModel=1
  do ibw=ibwa,ibwb
     b90=1.72**ibw
     call q65_intrinsics_ff(s3avg,nsubmode,b90/baud,nFadingModel,s3prob)
     call q65_dec_fullaplist(s3avg,s3prob,codewords,ncw,esnodb,dat4,plog,irc)
     if(irc.ge.0 .and. plog.ge.PLOG_MIN) then
        snr2=esnodb - db(2500.0/baud) + 3.0     !Empirical adjustment
        id1=1                                   !###
        write(c77,3050) dat4(1:12),dat4(13)/2
3050    format(12b6.6,b5.5)
        call unpack77(c77,0,avemsg,unpk77_success) !Unpack to get msgsent
        open(55,file='fort.55',status='unknown',position='append')
        write(55,3055) nutc,ibw,xdt,f0,85.0*base,ccfmax,snr2,plog,   &
             irc,trim(avemsg)
3055    format(i6,i3,6f8.2,i5,2x,a)
        close(55)
        print*,'F ',avemsg
        exit
     endif
  enddo

  APmask=0
  APsymbols=0
  read(41) LNZ,s3avg

  do ibw=ibwa,ibwb
     b90=1.72**ibw
     call q65_intrinsics_ff(s3avg,nsubmode,b90/baud,nFadingModel,s3prob)
     call q65_dec(s3avg,s3prob,APmask,APsymbols,esnodb,dat4,irc)
     print*,'G',ibw,irc,sum(s3avg)
     if(irc.ge.0) then
        id2=iaptype+2
        exit
     endif
  enddo  ! ibw (b90 loop)

900 return
end subroutine q65_avg
