      subroutine decode1a(dd,newdat,f0,nflip,mode65,nfsample,xpol,
     +  mycall,hiscall,hisgrid,neme,ndepth,nqd,dphi,ndphi,iloop,
     +  nutc,nkhz,ndf,ipol,ntol,sync2,a,dt,pol,nkv,nhist,nsum,nsave,
     +  qual,decoded)

!  Apply AFC corrections to a candidate JT65 signal, then decode it.

      parameter (NMAX=60*96000)          !Samples per 60 s
      real*4  dd(4,NMAX)                 !92 MB: raw data from Linrad timf2
      complex cx(NMAX/64), cy(NMAX/64)   !Data at 1378.125 samples/s
      complex c5x(NMAX/256),c5y(NMAX/256),c5tmp(NMAX/256)  !Data at 344.53125 Hz
      complex c5a(512)
      complex z
      real s2(66,126)
      real s3(64,63),sy(63)
      real a(5)
      logical first,xpol
      character decoded*22
      character mycall*12,hiscall*12,hisgrid*6
      data first/.true./,jjjmin/1000/,jjjmax/-1000/
      data nutc0/-999/,nhz0/-9999999/
      save

!  Mix sync tone to baseband, low-pass filter, downsample to 1378.125 Hz
      dt00=dt
      call timer('filbig  ',0)
      call filbig(dd,NMAX,f0,newdat,nfsample,xpol,cx,cy,n5)
!  NB: cx, cy have sample rate 96000*77125/5376000 = 1378.125 Hz
      call timer('filbig  ',1)
      joff=0
      sqa=0.
      sqb=0.
      do i=1,n5
         sqa=sqa + real(cx(i))**2 + aimag(cx(i))**2
         sqb=sqb + real(cy(i))**2 + aimag(cy(i))**2
      enddo
      sqa=sqa/n5
      sqb=sqb/n5

!  Find best DF, f1, f2, DT, and pol.  Start by downsampling to 344.53125 Hz
      z=cmplx(cos(dphi),sin(dphi))
      cy(:n5)=z*cy(:n5)                   !Adjust for cable length difference
      call timer('fil6521 ',0)
      call fil6521(cx,n5,c5x,n6)
      call fil6521(cy,n5,c5y,n6)
      call timer('fil6521 ',1)

! Add some zeros at start of c5 arrays -- empirical fix for negative DT's
! NB: might be better to add zeros to cx and cy, rather than here.
! Q: is the DT search range big enough?

      nadd=200
      c5tmp(1:nadd)=0.
      c5tmp(1+nadd:n6+nadd)=c5x(1:n6)
      c5x(1:n6+nadd)=c5tmp(1:n6+nadd)
      c5tmp(1+nadd:n6+nadd)=c5y(1:n6)
      c5y(1:n6+nadd)=c5tmp(1:n6+nadd)
      n6=n6+nadd

      fsample=1378.125/4.
      a(5)=dt00
      i0=nint((a(5)+0.5)*fsample) - 2 + 200
      if(i0.lt.1) then
         write(13,*) 'i0 too small in decode1a:',i0,f0
         flush(13)
         i0=1
      endif
      nz=n6+1-i0

! We're looking only at sync tone here... so why not downsample by another
! factor of 1/8, say?  Should be a significant execution speed-up.
      call timer('afc65b  ',0)
! Best fit for DF, f1, f2, pol
      call afc65b(c5x(i0),c5y(i0),nz,fsample,nflip,ipol,xpol,
     +     ndphi,iloop,a,ccfbest,dtbest)
      call timer('afc65b  ',1)

      pol=a(4)/57.2957795
      aa=cos(pol)
      bb=sin(pol)
      sq0=aa*aa*sqa + bb*bb*sqb
      sync2=3.7*ccfbest/sq0

!  Apply AFC corrections to the time-domain signal
!  Now we are back to using the 1378.125 Hz sample rate, enough to 
!  accommodate the full JT65C bandwidth.

      call timer('twkfreq ',0)
      call twkfreq(cx,cy,n5,a)
      call timer('twkfreq ',1)

!  Compute spectrum at best polarization for each half symbol.
!  Adding or subtracting a small number (e.g., 5) to j may make it decode.\
!  NB: might want to try computing full-symbol spectra (nfft=512, even for
!  submodes B and C).

      nsym=126
      nfft=512/mode65
      j=(dt00+dtbest+2.685)*1378.125 + joff
      if(j.lt.0) j=0

      call timer('sh_ffts ',0)

! Perhaps should try full-symbol-length FFTs even in B, C sub-modes?
! (Tried this, found no significant difference in decodes.)

      do k=1,nsym
         do n=1,mode65
            do i=1,nfft
               j=j+1
               c5a(i)=aa*cx(j) + bb*cy(j)
            enddo
            call four2a(c5a,nfft,1,1,1)
            if(n.eq.1) then
               do i=1,66
                  s2(i,k)=real(c5a(i))**2 + aimag(c5a(i))**2
               enddo
            else
               do i=1,66
                  s2(i,k)=s2(i,k) + real(c5a(i))**2 + aimag(c5a(i))**2
               enddo
            endif
         enddo
      enddo

      call timer('sh_ffts ',1)

      flip=nflip
      call timer('dec65b  ',0)
      call decode65b(s2,flip,mycall,hiscall,hisgrid,mode65,neme,ndepth,
     +    nqd,nkv,nhist,qual,decoded,s3,sy)
      dt=dt00 + dtbest
      call timer('dec65b  ',1)

      if(nqd.eq.1 .and. nkv.eq.0) then
         nhz=1000*nkhz + ndf
         ihzdiff=min(500,ntol)
         if(nutc.ne.nutc0 .or. abs(nhz-nhz0).ge.ihzdiff) syncbest=0.
         if(sync2.gt.syncbest) then
            nsave=nsave+1
            nsave=mod(nsave-1,64)+1
            npol=nint(57.296*pol)
            xdt=dt+0.8

            call s3avg(nsave,mode65,nutc,nhz,xdt,npol,ntol,s3,nsum,
     +                 nkv,decoded)
            syncbest=sync2
            nhz0=nhz
         endif
         nutc0=nutc
      endif

      return
      end
