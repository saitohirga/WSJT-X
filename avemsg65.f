      subroutine avemsg65(mseg,mode65,ndepth,decoded,nused,ns,ncount)

C  Decodes averaged JT65 data for the specified segment (mseg=1 or 2).

      parameter (MAXAVE=120)                    !Max avg count is 120
      character decoded*22
      real s3(64,63)
      common/ave/ppsave(64,63,MAXAVE),nflag(MAXAVE),nsave,iseg(MAXAVE)

C  Count the available spectra for this Monitor segment (mseg=1 or 2),
C  and the number of spectra flagged as good.

      nused=0
      ns=0
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
      call extract(s3,nadd,ndepth,ncount,decoded)     !Extract the message
 100  if(nused.lt.1.or.ncount.lt.0) decoded='                      '

C  Suppress "birdie messages":
      if(decoded(1:7).eq.'000AAA ') decoded='                      '
      if(decoded(1:7).eq.'0L6MWK ') decoded='                      '

!      print*,mseg,nused,' ',decoded

      return
      end
