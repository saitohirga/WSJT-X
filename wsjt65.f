      subroutine wsjt65(dat,npts,cfile6,NClearAve,MinSigdB,
     +  DFTolerance,NFreeze,NAFC,mode65,Nseg,MouseDF,NAgain,
     +  naggressive,ndepth,neme,nsked,mycall,hiscall,hisgrid,
     +  lumsg,lcum,nspecial,ndf,nstest,dfsh,iderrsh,idriftsh,
     +  snrsh,NSyncOK,ccfblue,ccfred,ndiag,nwsh)

C  Orchestrates the process of decoding JT65 messages, using data that
C  have been 2x downsampled.  The search for shorthand messages has
C  already been done.

      real dat(npts)                        !Raw data
      integer DFTolerance
      logical first
      logical lcum
      character decoded*22,cfile6*6,special*5,cooo*3
      character*22 avemsg1,avemsg2,deepmsg,deepbest
      character*67 line,ave1,ave2
      character*1 csync,c1
      character*12 mycall
      character*12 hiscall
      character*6 hisgrid
      real ccfblue(-5:540),ccfred(-224:224)
      real ftrack(126)
      logical lmid
      integer itf(2,9)
      include 'avecom.h'
      common/avecom2/f0a
      data first/.true./,ns10/0/,ns20/0/
      data itf/0,0, 1,0, -1,0, 0,-1, 0,1, 1,-1, 1,1, -1,-1, -1,1/
      save

      if(first) then
         call setup65                   !Initialize pseudo-random arrays
         nsave=0
         first=.false.
         ave1=' '
         ave2=' '
      endif

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

C  Attempt to synchronize: look for sync tone, get DF and DT.
      call sync65(dat,npts,DFTolerance,NFreeze,NAFC,MouseDF,
     +    dtx,dfx,snrx,snrsync,ccfblue,ccfred,flip,width,ftrack)
      f0=1270.46 + dfx
      csync=' '
      decoded='                      '
      special='     '
      cooo='   '
      itry=0
      ncount=-1             !Flag for RS decode of current record
      ncount1=-1            !Flag for RS Decode of ave1
      ncount2=-1            !Flag for RS Decode of ave2
      NSyncOK=0
      qbest=0.

      if(nsave.lt.MAXAVE .and. (NAgain.eq.0 .or. NClearAve.eq.1)) 
     +  nsave=nsave+1
      if(nsave.le.0) go to 900          !Prevent bounds error

      nflag(nsave)=0                    !Clear the "good sync" flag
      iseg(nsave)=Nseg                  !Set the RX segment to 1 or 2
      nsync=nint(snrsync-3.0)
      nsnr=nint(snrx)
      if(nsnr.lt.-30 .or. nsync.lt.0) nsync=0
      nsnrlim=-32

C  Good Sync takes precedence over a shorthand message:
      if(nsync.ge.MinSigdB .and. nsnr.ge.nsnrlim .and.
     +   nsync.gt.nstest) nstest=0

      if(nstest.gt.0) then
         dfx=dfsh
         nsync=nstest
         nsnr=snrsh
         dtx=1.
         ccfblue(-5)=-999.0
         if(nspecial.eq.1) special='ATT  '
         if(nspecial.eq.2) special='RO   '
         if(nspecial.eq.3) special='RRR  '
         if(nspecial.eq.4) special='73   '
         NSyncOK=1              !Mark this RX file as good (for "Save Decoded")
         if(NFreeze.eq.0 .or. DFTolerance.ge.200) special(5:5)='?'
         width=nwsh
         go to 200
      endif

      if(nsync.lt.MinSigdB .or. nsnr.lt.nsnrlim) go to 200

C  If we get here, we have achieved sync!
      NSyncOK=1
      nflag(nsave)=1            !Mark this RX file as good
      csync='*'
      if(flip.lt.0.0) then
         csync='#'
         cooo='O ?'
      endif

C  Do a "peakup search" over DT, looking for successful 
C  result from the Reed-Solomon decoder.
      itrymax=1
      if(ndepth.eq.2) itrymax=1
      if(ndepth.eq.3) itrymax=5

      do itry=1,itrymax
         idt=itf(1,itry)
         idf=itf(2,itry)
         dtxx=dtx + idt*0.036             !### Was 0.012 ###
         dfxx=dfx + mode65*idf*1.346
         lmid=.false.
         if(itry.eq.1) lmid=.true.
         call decode65(dat,npts,dtxx,dfxx,flip,ndepth,neme,nsked,
     +        mycall,hiscall,hisgrid,mode65,lmid,ftrack,decoded,
     +        ncount,deepmsg,qual)
         if(ncount.eq.-999) then
            qbest=0                       !Bad data
            go to 200
         endif
         if(qual.gt.qbest) then
            qbest=qual
            dtbest=dtxx
            dfbest=dfxx
            deepbest=deepmsg
            itrybest=itry
         endif
         if(ncount.ge.0) then
            dtx=dtxx                      !Successful decode
            dfx=dfxx
            go to 200
         endif
      enddo
      itry=itrybest
      ncount=-1

 200  continue
      kvqual=0
      if(ncount.ge.0) kvqual=1
      nqual=qbest
      if(nqual.ge.nq1 .and.kvqual.eq.0) then
         dtx=dtbest
         dfx=dfbest
         decoded=deepbest
      endif

      ndf=nint(dfx)
      if(flip.lt.0.0 .and. (kvqual.eq.1 .or. nqual.ge.nq2)) cooo='OOO'
      if(kvqual.eq.0.and.nqual.ge.nq1.and.nqual.lt.nq2) cooo(2:3)=' ?'
      if(decoded.eq.'                      ') cooo='   '
      do i=1,22
         c1=decoded(i:i)
         if(c1.ge.'a' .and. c1.le.'z') decoded(i:i)=char(ichar(c1)-32)
      enddo
      write(line,1010) cfile6,nsync,nsnr,dtx-1.0,ndf,
     +    nint(width),csync,special,decoded(1:18),cooo,kvqual,nqual,itry
 1010 format(a6,i3,i5,f5.1,i5,i3,1x,a1,1x,a5,a18,1x,a3,i5,i3,i2)

C  Blank DT if shorthand message  (### wrong logic? ###)
      if(special.ne.'     ') then
         line(15:19)='     '
         ccfblue(-5)=-9999.0
         if(ndiag.gt.0) write(line(51:57),1012) iderrsh,idriftsh
 1012    format(i3,i4)
      else
         nspecial=0
      endif

C  Blank the end-of-line numbers
      if(naggressive.eq.0 .and. ndiag.eq.0) line(58:67)='         '
      if(ndiag.eq.0) line(66:67)='  '

      if(lcum) write(21,1011) line
 1011 format(a67)
C  Write decoded msg unless this is an "Exclude" request:
      if(MinSigdB.lt.99) write(lumsg,1011) line

      if(nsave.ge.1) call avemsg65(1,mode65,ndepth,avemsg1,nused1,
     +     ns1,ncount1)
      if(nsave.ge.1) call avemsg65(2,mode65,ndepth,avemsg2,nused2,
     +     ns2,ncount2)

C  Write the average line
      if(ns1.ge.1 .and. ns1.ne.ns10) then
         if(ns1.lt.10) write(ave1,1021) cfile6,1,nused1,ns1,avemsg1
 1021    format(a6,i3,i4,'/',i1,20x,a18)
         if(ns1.ge.10 .and. nsave.le.99) write(ave1,1022) cfile6,
     +     1,nused1,ns1,avemsg1
 1022    format(a6,i3,i4,'/',i2,19x,a18)
         if(ns1.ge.100) write(ave1,1023) cfile6,1,nused1,ns1,
     +     avemsg1
 1023    format(a6,i3,i4,'/',i3,18x,a18)
         if(lcum .and. (avemsg1.ne.'                  ')) 
     +      write(21,1011) ave1(1:57)//'         '
         ns10=ns1
      endif

C  If Monitor segment #2 is available, write that line also
      if(ns2.ge.1 .and. ns2.ne.ns20) then
         if(ns2.lt.10) write(ave2,1021) cfile6,2,nused2,ns2,avemsg2
         if(ns2.ge.10 .and. nsave.le.99) write(ave2,1022) cfile6,
     +     2,nused2,ns2,avemsg2
         if(ns2.ge.100) write(ave2,1023) cfile6,2,nused2,ns2,avemsg2
         if(lcum .and. (avemsg2.ne.'                  ')) 
     +      write(21,1011) ave2(1:57)//'         '
         ns20=ns2
      endif

      if(ndiag.eq.0) then
         ave1(58:67)='         '
         ave2(58:67)='         '
      endif
      write(12,1011) ave1
      write(12,1011) ave2
      call flushqqq(12)
 
 800  if(lumsg.ne.6) end file 11
      f0a=f0

 900  continue

      return
      end
