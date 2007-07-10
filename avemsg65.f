      subroutine avemsg65(mseg,mode65,ndepth,decoded,nused,
     +  nq1,nq2,neme,nsked,mycall,hiscall,hisgrid,qual,
     +  ns,ncount)

C  Decodes averaged JT65 data for the specified segment (mseg=1 or 2).

      parameter (MAXAVE=120)                    !Max avg count is 120
      character decoded*22,deepmsg*22
      character mycall*12,hiscall*12,hisgrid*6
      real s3(64,63)
      logical ltext
      common/ave/ppsave(64,63,MAXAVE),nflag(MAXAVE),nsave,iseg(MAXAVE)

C  Count the available spectra for this Monitor segment (mseg=1 or 2),
C  and the number of spectra flagged as good.

      nused=0
      ns=0
      nqual=0
      deepmsg='                      '
      do i=1,nsave
         if(iseg(i).eq.mseg) then
            ns=ns+1
            if(nflag(i).eq.1) nused=nused+1
         endif
      enddo
      if(nused.lt.1) go to 100

C  Compute the average of all flagged spectra for this segment.
      do j=1,63
         call zero(s3(1,j),64)
         do n=1,nsave
            if(nflag(n).eq.1 .and. iseg(n).eq.mseg) then
               call add(s3(1,j),ppsave(1,j,n),s3(1,j),64)
            endif
         enddo
      enddo

      nadd=nused*mode65
      call extract(s3,nadd,ncount,decoded,ltext)     !Extract the message
      if(ncount.lt.0) decoded='                      '

      nqual=0
C  Possibly should pass nadd=nused, also:
      if(ndepth.ge.3) then
         flipx=1.0                     !Normal flip not relevant for ave msg
         call deep65(s3,mode65,neme,nsked,flipx, 
     +   mycall,hiscall,hisgrid,deepmsg,qual)
         nqual=qual
         if(nqual.lt.nq1) deepmsg='                      '
         if(nqual.ge.nq1 .and. nqual.lt.nq2) deepmsg(19:19)='?'
      else
         deepmsg='                      '
         qual=0.
      endif
      if(ncount.lt.0) decoded=deepmsg

C  Suppress "birdie messages":
      if(decoded(1:7).eq.'000AAA ') decoded='                      '
      if(decoded(1:7).eq.'0L6MWK ') decoded='                      '

 100  if(nused.lt.1) decoded='                      '
      return
      end
