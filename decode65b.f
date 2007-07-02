      subroutine decode65b(s2,flip,mycall,hiscall,hisgrid,neme,ndepth,
     +  nqd,nkv,nhist,qual,decoded)

      real s2(256,126)
      real s3(64,63)
      logical first
      character decoded*22,deepmsg*22
      character mycall*12,hiscall*12,hisgrid*6
!      include 'avecom.h'
      include 'prcom.h'
      data first/.true./
      save

      if(first) call setup65
      first=.false.

      call setup65
      do j=1,63
         k=mdat(j)                       !Points to data symbol
         if(flip.lt.0.0) k=mdat2(j)
         do i=1,64
            s3(i,j)=s2(i+2,k)            !### Check the "i+2" ###
         enddo
      enddo
      mode65=2
      nadd=mode65

      call extract(s3,nadd,ncount,nhist,decoded)     !Extract the message
C  Suppress "birdie messages":
      if(decoded(1:7).eq.'000AAA ') ncount=-1
      if(decoded(1:7).eq.'0L6MWK ') ncount=-1
      nkv=1
      if(ncount.lt.0) then 
         nkv=0
         decoded='                      '
      endif

      qual=0.
!      if(nkv.eq.0) then
         if(ndepth.ge.1) call deep65(s3,mode65,neme,
     +        flip,mycall,hiscall,hisgrid,deepmsg,qual)
         if(nqd.ne.1 .and. qual.lt.10.0) qual=0.0

C  Save symbol spectra for possible decoding of average.
!      do j=1,63
!         k=mdat(j)
!         if(flip.lt.0.0) k=mdat2(j)
!         call move(s2(8,k),ppsave(1,j,nsave),64)
!      enddo

!      endif

      if(nkv.eq.0 .and. qual.ge.1.0) decoded=deepmsg

      return
      end
