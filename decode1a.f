      subroutine decode1a(id,newdat,nfilt,freq,nflip,
     +         mycall,hiscall,hisgrid,neme,ndepth,nqd,dphi,ndphi,
     +         ipol,sync2,a,dt,pol,nkv,nhist,qual,decoded)

C  Apply AFC corrections to a candidate JT65 signal, and then try
C  to decode it.

      parameter (NFFT1=77760,NFFT2=2430)
      parameter (NMAX=60*96000)          !Samples per 60 s
      integer*2 id(4,NMAX)               !46 MB: raw data from Linrad timf2
      complex c2x(NMAX/4), c2y(NMAX/4)   !After 1/4 filter and downsample
      complex c3x(NMAX/16),c3y(NMAX/16)  !After 1/16 filter and downsample
      complex c4x(NMAX/64),c4y(NMAX/64)  !After 1/64 filter and downsample
      complex cx(NMAX/64), cy(NMAX/64)   !Data at 1378.125 samples/s
      complex c5x(NMAX/256),c5y(NMAX/256),c5y0(NMAX/256)
      complex c5a(256),    c5b(256)
      complex z

      real s2(256,126)
      real a(5)
      real*8 samratio
      integer resample
      logical first
      character decoded*22
      character mycall*12,hiscall*12,hisgrid*6
      data first/.true./,jjjmin/1000/,jjjmax/-1000/
      save

C  Mix sync tone to baseband, low-pass filter, and decimate by 64
      dt00=dt
C  If freq=125.0 kHz, f0=48000 Hz.
      f0=1000*(freq-77.0)                  !Freq of sync tone (0-96000 Hz)
      if(nfilt.eq.1) then
         call filbig(id,NMAX,f0,newdat,cx,cy,n5)
         joff=0
      else
         call fil659(id,NMAX,f0,c2x,c2y,n2) !Pass 1: mix and filter both pol'ns
         call fil658(c2x,n2,c3x,n3) !Pass 2
         call fil658(c2y,n2,c3y,n3)
         call fil658(c3x,n3,c4x,n4) !Pass 3
         call fil658(c3y,n3,c4y,n4)
         joff=-8

C  Resample from 96000/64 = 1500 Hz to 1378.125 Hz
C  Converter type: 0=Best quality sinc (band limited), BW=97%
C                  1=medium quality sinc, BW=90%
C                  2=fastest sinc,  BW=80%
C                  3=stepwise (very fast)
C                  4=linear (very fast)
         nconv_type=2           !### test! ###
         nchans=2
         samratio=1378.125d0/1500.d0
         i1=resample(c4x,n4,nconv_type,nchans,samratio,cx,n5)
         i2=resample(c4y,n4,nconv_type,nchans,samratio,cy,n5)
      endif

      sqa=0.
      sqb=0.
      do i=1,n5
         sqa=sqa + real(cx(i))**2 + aimag(cx(i))**2
         sqb=sqb + real(cy(i))**2 + aimag(cy(i))**2
      enddo
      sqa=sqa/n5
      sqb=sqb/n5

C  Find best DF, f1, f2, DT, and pol

!      a(5)=dt00
!      fsample=1378.125
!      i0=nint((a(5)+0.5)*fsample)
!      if(i0.lt.1) i0=1
!      nz=n5+1-i0
!      call afc65b(cx(i0),cy(i0),nz,fsample,nflip,ipol,a,dt,
!     +    ccfbest,dtbest)

      call fil6521(cx,n5,c5x,n6)
      call fil6521(cy,n5,c5y0,n6)

!  Adjust for cable length difference:
      z=cmplx(cos(dphi),sin(dphi))
      do i=1,n6
         c5y(i)=z*c5y0(i)
      enddo

      fsample=1378.125/4.
      a(5)=dt00
      i0=nint((a(5)+0.5)*fsample) - 2
      if(i0.lt.1) i0=1
      nz=n6+1-i0

      call afc65b(c5x(i0),c5y(i0),nz,fsample,nflip,ipol,a,dt,
     +     ccfbest,dtbest)

      pol=a(4)/57.2957795
      aa=cos(pol)
      bb=sin(pol)
      sq0=aa*aa*sqa + bb*bb*sqb
      sync2=3.7*ccfbest/sq0

C  Apply AFC corrections to the time-domain signal
      call twkfreq(cx,cy,n5,a)

C  Compute spectrum at best polarization for each half symbol.
C  Adding or subtracting a small number (e.g., 5) to j may make it decode.
      nsym=126
      nfft=256
      j=(dt00+dtbest+2.685)*1378.125 + joff
      if(j.lt.0) j=0
      j0=j
      do k=1,nsym
         do i=1,nfft
            j=j+1
            c5a(i)=aa*cx(j) + bb*cy(j)
         enddo
         call four2a(c5a,nfft,1,1,1)
         do i=1,nfft
            j=j+1
            c5b(i)=aa*cx(j) + bb*cy(j)
         enddo
         call four2a(c5b,nfft,1,1,1)

         do i=1,256
            s2(i,k)=real(c5a(i))**2 + aimag(c5a(i))**2 +
     +           real(c5b(i))**2 + aimag(c5b(i))**2
         enddo
      enddo

      flip=nflip
      call decode65b(s2,flip,mycall,hiscall,hisgrid,neme,ndepth,
     +    nqd,nkv,nhist,qual,decoded)
      dt=dt00 + dtbest

      return
      end
