      subroutine decode65(dat,npts,dtx,dfx,flip,ndepth,neme,nsked,
     +  mycall,hiscall,hisgrid,mode65,lsave,ftrack,decoded,ncount,
     +  deepmsg,qual)

C  Decodes JT65 data, assuming that DT and DF have already been determined.

      real dat(npts)                        !Raw data
      real s2(77,126)
      real s3(64,63)
      real ftrack(126)
      logical lsave
      character decoded*22,deepmsg*22
      character mycall*12,hiscall*12,hisgrid*6
      include 'avecom.h'
      include 'prcom.h'
      save

      dt=2.0/11025.0                   !Sample interval (2x downsampled data)
      istart=nint(dtx/dt)              !Start index for synced FFTs
      nsym=126

C  Compute FFTs of symbols
      f0=1270.46 + dfx
      call spec2d65(dat,npts,nsym,flip,istart,f0,ftrack,mode65,s2)

      do j=1,63
         k=mdat(j)                       !Points to data symbol
         if(flip.lt.0.0) k=mdat2(j)
         do i=1,64
            s3(i,j)=s2(i+7,k)
         enddo
      enddo
      nadd=mode65

      call extract(s3,nadd,ndepth,ncount,decoded)     !Extract the message
c      if(lsave) call deep65(s3,mode65,neme,nsked,flip,mycall,hiscall,hisgrid,
      call deep65(s3,mode65,neme,nsked,flip,mycall,hiscall,hisgrid,
     +     deepmsg,qual)

      if(ncount.lt.0) decoded='                      '

C  Suppress "birdie messages":
      if(decoded(1:7).eq.'000AAA ') decoded='                      '
      if(decoded(1:7).eq.'0L6MWK ') decoded='                      '

C  If ncount>=0 or if this is the "0,0" run, save spectrum in ppsave:
C  Q: should ftrack be used here?
 100  if((ncount.ge.0 .or. lsave)) then
         do j=1,63
            k=mdat(j)
            if(flip.lt.0.0) k=mdat2(j)
            call move(s2(8,k),ppsave(1,j,nsave),64)
         enddo
      endif

      return
      end
