subroutine wsjt24(dat,npts,cfile6,NClearAve,MinSigdB,                  &
     DFTolerance,NFreeze,mode,mode4,Nseg,MouseDF,NAgain,               &
     idf,lumsg,lcum,nspecial,ndf,NSyncOK,ccfblue,ccfred,ndiag)

! Orchestrates the process of decoding JT4 messages, using data that 
! have been 2x downsampled.  
! No message averaging and no deep search, at present.

  parameter (MAXAVE=120)
  real dat(npts)                                     !Raw data
  real*4 ccfblue(-5:540)                             !CCF in time
  real*4 ccfred(-224:224)                            !CCF in frequency
  integer DFTolerance
  logical first
  logical lcum
  character decoded*22,cfile6*6,special*5,cooo*3
  character*22 avemsg1,avemsg2,deepmsg
  character*77 line,ave1,ave2
  character*1 csync,c1
  character*12 mycall
  character*12 hiscall
  character*6 hisgrid
  character submode*1
  real*4 ccfbluesum(-5:540),ccfredsum(-224:224)
!  common/ave/ppsave(64,63,MAXAVE),nflag(MAXAVE),nsave,iseg(MAXAVE) !For msg avg
  integer nflag(MAXAVE),iseg(MAXAVE)
  data first/.true./,ns10/0/,ns20/0/
  save

  if(first) then
     nsave=0
     first=.false.
     ave1=' '
     ave2=' '
     ccfblue=0.
     ccfred=0.
     if(nspecial.eq.999) go to 900        !Silence compiler warning
  endif

  naggressive=0
  if(ndepth.ge.2) naggressive=1
  nq1=3
  nq2=6
  if(naggressive.eq.1) nq1=1

  if(NClearAve.ne.0) then
     nsave=0                        !Clear the averaging accumulators
     ns10=0
     ns20=0
     ave1=' '
     ave2=' '
  endif
  if(MinSigdB.eq.99 .or. MinSigdB.eq.-99) then
     ns10=0                         !For Include/Exclude ?
     ns20=0
  endif

! Attempt to synchronize: look for sync pattern, get DF and DT.
  call sync24(dat,npts,DFTolerance,NFreeze,MouseDF,mode,             &
       mode4,dtx,dfx,snrx,snrsync,ccfblue,ccfred,flip,width)

  csync=' '
  decoded='                      '
  deepmsg='                      '
  special='     '
  cooo='   '
  ncount=-1             !Flag for RS decode of current record
  ncount1=-1            !Flag for RS Decode of ave1
  ncount2=-1            !Flag for RS Decode of ave2
  NSyncOK=0
  nqual1=0
  nqual2=0

  if(nsave.lt.MAXAVE .and. (NAgain.eq.0 .or. NClearAve.eq.1)) nsave=nsave+1
  if(nsave.le.0) go to 900          !Prevent bounds error
  
  nflag(nsave)=0                    !Clear the "good sync" flag
  iseg(nsave)=Nseg                  !Set the RX segment to 1 or 2
  nsync=nint(snrsync-3.0)
  nsnr=nint(snrx)
  if(nsnr.lt.-30 .or. nsync.lt.0) nsync=0
  nsnrlim=-33
  if(nsync.lt.MinSigdB .or. nsnr.lt.nsnrlim) go to 200

! If we get here, we have achieved sync!
  NSyncOK=1
  nflag(nsave)=1            !Mark this RX file as good
  csync='*'
  if(flip.lt.0.0) then
     csync='#'
     cooo='O ?'
  endif

  call decode24(dat,npts,dtx,dfx,flip,mode,mode4,decoded,           &
       ncount,deepmsg,qual,submode)

200 kvqual=0
  if(ncount.ge.0) kvqual=1
  nqual=qual
  if(ndiag.eq.0 .and. nqual.gt.10) nqual=10
  if(nqual.ge.nq1 .and.kvqual.eq.0) decoded=deepmsg

  ndf=nint(dfx)
  if(flip.lt.0.0 .and. (kvqual.eq.1 .or. nqual.ge.nq2)) cooo='OOO'
  if(kvqual.eq.0.and.nqual.ge.nq1.and.nqual.lt.nq2) cooo(2:3)=' ?'
  if(decoded.eq.'                      ') cooo='   '
  do i=1,22
     c1=decoded(i:i)
     if(c1.ge.'a' .and. c1.le.'z') decoded(i:i)=char(ichar(c1)-32)
  enddo
  jdf=ndf+idf

!  call cs_lock('wsjt24')
  write(line,1010) cfile6,nsync,nsnr,dtx-1.0,jdf,nint(width),         &
       csync,special,decoded(1:19),cooo,kvqual,nqual,submode
1010 format(a6,i3,i5,f5.1,i5,i3,1x,a1,1x,a5,a19,1x,a3,i3,i5,1x,a1)

! Blank all end-of-line stuff if no decode
  if(line(31:40).eq.'          ') line=line(:30)

!  if(lcum) write(21,1011) line

! Write decoded msg unless this is an "Exclude" request:
  if(MinSigdB.lt.99) write(*,1011) line
1011 format(a77)

!  if(nsave.ge.1) call avemsg65(1,mode65,ndepth,                      &
!       avemsg1,nused1,nq1,nq2,neme,mycall,hiscall,hisgrid,qual1,     &
!       ns1,ncount1)
!  if(nsave.ge.1) call avemsg65(2,mode65,ndepth,                      &
!       avemsg2,nused2,nq1,nq2,neme,mycall,hiscall,hisgrid,qual2,     &
!       ns2,ncount2)
  nqual1=qual1
  nqual2=qual2
  if(ndiag.eq.0 .and. nqual1.gt.10) nqual1=10
  if(ndiag.eq.0 .and. nqual2.gt.10) nqual2=10
  nc1=0
  nc2=0
  if(ncount1.ge.0) nc1=1
  if(ncount2.ge.0) nc2=1

! Write the average line
!      if(ns1.ge.1 .and. ns1.ne.ns10) then

!  if(ns1.ge.1) then
!     if(ns1.lt.10) write(ave1,1021) cfile6,1,nused1,ns1,avemsg1,nc1,nqual1
!1021 format(a6,i3,i4,'/',i1,20x,a19,i8,i4)
!     if(ns1.ge.10 .and. nsave.le.99) write(ave1,1022) cfile6,        &
!          1,nused1,ns1,avemsg1,nc1,nqual1
!1022 format(a6,i3,i4,'/',i2,19x,a19,i8,i4)
!     if(ns1.ge.100) write(ave1,1023) cfile6,1,nused1,ns1,            &
!          avemsg1,nc1,nqual1
!1023 format(a6,i3,i4,'/',i3,18x,a19,i8,i4)
!     if(lcum .and. (avemsg1.ne.'                  '))                &
!          write(21,1011) ave1
!     ns10=ns1
!  endif

! If Monitor segment #2 is available, write that line also
!      if(ns2.ge.1 .and. ns2.ne.ns20) then     !***Why the 2nd part?? ***
!  if(ns2.ge.1) then
!     if(ns2.lt.10) write(ave2,1021) cfile6,2,nused2,ns2,avemsg2,nc2,nqual2
!     if(ns2.ge.10 .and. nsave.le.99) write(ave2,1022) cfile6,       &
!          2,nused2,ns2,avemsg2,nc2,nqual2
!     if(ns2.ge.100) write(ave2,1023) cfile6,2,nused2,ns2,avemsg2,nc2,nqual2
!     if(lcum .and. (avemsg2.ne.'                  '))               &
!          write(21,1011) ave2
!     ns20=ns2
!  endif

  if(ave1(31:40).eq.'          ') ave1=ave1(:30)
  if(ave2(31:40).eq.'          ') ave2=ave2(:30)
!  write(12,1011) ave1
!  write(12,1011) ave2
!  call flush(12)
!  call cs_unlock
  
900 continue

  ccfbluesum=ccfbluesum + ccfblue
  ccfredsum=ccfredsum + ccfred

! This was for testing message averaging:

!  rewind 71
!  rewind 72
!  do i=-5,540
!     write(71,3001) 0.2 + i*0.057143,ccfbluesum(i)
!3001 format(2f12.3)
!  enddo
!  do i=-224,224
!     write(72,3001) i*2.1875,ccfredsum(i)
!  enddo
!  call flush(71)
!  call flush(72)

  return
end subroutine wsjt24
