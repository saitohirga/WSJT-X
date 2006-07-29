      subroutine decode65(dat,npts,dtx,dfx,flip,ndepth,neme,nsked,
     +  nsnr,mycall,hiscall,hisgrid,mode65,nafc,decoded,ncount,
     +  deepmsg,qual)

C  Decodes JT65 data, assuming that DT and DF have already been determined.

      real dat(npts)                        !Raw data
      real s2(77,126)
      real s3(64,63)
      real ftrack(126)
      character decoded*22,deepmsg*22
      character mycall*12,hiscall*12,hisgrid*6
      include 'avecom.h'
      include 'prcom.h'
      save

      dt=2.0/11025.0                   !Sample interval (2x downsampled data)
      istart=nint(dtx/dt)              !Start index for synced FFTs
      nsym=126

C  Compute spectra of the channel symbols
      f0=1270.46 + dfx
      call spec2d65(dat,npts,nsym,flip,istart,f0,ftrack,nafc,mode65,s2)

      do j=1,63
         k=mdat(j)                       !Points to data symbol
         if(flip.lt.0.0) k=mdat2(j)
         do i=1,64
            s3(i,j)=s2(i+7,k)
         enddo
      enddo
      nadd=mode65

      call extract(s3,nadd,ndepth,ncount,decoded)     !Extract the message
      qual=0.
      if(ndepth.ge.1) call deep65(s3,mode65,neme,
     +    nsked,flip,mycall,hiscall,hisgrid,deepmsg,qual)

      if(ncount.lt.0) decoded='                      '

C  Suppress "birdie messages":
      if(decoded(1:7).eq.'000AAA ') decoded='                      '
      if(decoded(1:7).eq.'0L6MWK ') decoded='                      '

C  Save symbol spectra for possible decoding of average.
      do j=1,63
         k=mdat(j)
         if(flip.lt.0.0) k=mdat2(j)
         call move(s2(8,k),ppsave(1,j,nsave),64)
      enddo

      return
      end
