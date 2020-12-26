subroutine q65_avg(nutc,ntrperiod,mode_q65,LL,nfqso,ntol,lclearave,xdt,f0,snr1,s3)

! Accumulate and decode averaged Q65 data

  use q65
!  class(q65_decoder), intent(inout) :: this
  character*37 avemsg
  character*1 csync,cused(MAXAVE)
  character*6 cutc
  real s3(-64:LL-65,63)
  integer iused(MAXAVE)
  logical first,lclearave
  data first/.true./
  save

  if(first .or. LL.ne.LL0 .or.lclearave) then
     iutc=-1
     iseq=-1
     fsave=0.0
     dtdiff=0.2
     nsave=0
     LL0=LL
     first=.false.
     if(allocated(s3save)) deallocate(s3save)
     if(allocated(s3avg)) deallocate(s3avg)
     allocate(s3save(-64:LL-65,63,MAXAVE))
     allocate(s3avg(-64:LL-65,63))
  endif

  do i=1,MAXAVE       !Don't save info more than once for same UTC and freq
     if(nutc.eq.iutc(i) .and. abs(nfreq-fsave(i)).le.ntol) go to 10
  enddo

! Save data for message averaging
  nsave=nsave+1
  n=nutc
  if(ntrperiod.ge.60) n=100*n
  write(cutc,'(i6.6)') n
  read(cutc,'(3i2)') ih,im,is
  nsec=3600*ih + 60*im + is
  iseq(nsave)=mod(nsec/ntrperiod,2)
  iutc(nsave)=nutc
  snr1save(nsave)=snr1
  xdtsave(nsave)=xdt
  fsave(nsave)=f0
  s3save(:,:,nsave)=s3(:,:)
!  write(*,3001) nutc,iseq(nsave),nsave,ntrperiod,LL,nfqso,ntol,xdt,f0,snr1
!3001 format(i6,i2,5i5,3f7.1)

10 snr1sum=0.
  xdtsum=0.
  fsum=0.
  nsum=0

  do i=1,MAXAVE
     cused(i)='.'
     if(iutc(i).lt.0) cycle
     if(mod(iutc(i),2).ne.mod(nutc,2)) cycle  !Use only same sequence
     if(abs(dtxx-xdtsave(i)).gt.dtdiff) cycle  !DT must match
     if(abs(nfreq-fsave(i)).gt.ntol) cycle   !Freq must match
!     sym(1:207,1:7)=sym(1:207,1:7) +  ppsave(1:207,1:7,i)
     snr1sum=snr1sum + snr1save(i)
     xdtsum=xdtsum + xdtsave(i)
     fsum=fsum + fsave(i)
     cused(i)='$'
     nsum=nsum+1
     iused(nsum)=i
  enddo
  if(nsum.lt.MAXAVE) iused(nsum+1)=0

  snr1ave=0.
  xdtave=0.
  fave=0.
  if(nsum.gt.0) then
     snr1ave=snr1sum/nsum
     xdtave=xdtsum/nsum
     fave=fsum/nsum
  endif

  do i=1,nsave
     csync=' '
!     if(nflipsave(i).gt.0.0) csync='*'
     if(ntrperiod.le.30) write(14,1000) cused(i),iutc(i),snr1save(i),    &
          xdtsave(i),fsave(i),csync
1000 format(a1,i7.6,f6.1,f6.2,f7.1,1x,a1)
     if(ntrperiod.ge.60) write(14,1001) cused(i),iutc(i),snr1save(i),    &
          xdtsave(i),fsave(i),csync
1001 format(a1,i5.4,f6.1,f6.2,f7.1,1x,a1)
  enddo
  if(nsum.lt.2) go to 900

  sqt=0.
  sqf=0.
  do j=1,MAXAVE
     i=iused(j)
     if(i.eq.0) exit
     csync='*'
     sqt=sqt + (xdtsave(i)-dtave)**2
     sqf=sqf + (fsave(i)-fave)**2
  enddo
  rmst=0.
  rmsf=0.
  if(nsum.ge.2) then
     rmst=sqrt(sqt/(nsum-1))
     rmsf=sqrt(sqf/(nsum-1))
  endif

900 return
end subroutine q65_avg
