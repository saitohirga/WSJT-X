subroutine decode65a(dd,npts,newdat,nqd,f0,nflip,mode65,sync2,a,dt,    &
     nbmkv,nhist,decoded)

! Apply AFC corrections to a candidate JT65 signal, then decode it.

  parameter (NMAX=60*12000)          !Samples per 60 s
  real*4  dd(NMAX)                   !92 MB: raw data from Linrad timf2
  complex cx(NMAX/8)                 !Data at 1378.125 samples/s
  complex c5x(NMAX/32)               !Data at 344.53125 Hz
  complex c5a(512)
  real s2(66,126)
  real a(5)
  logical first
  character decoded*22
  data first/.true./,jjjmin/1000/,jjjmax/-1000/
  data nhz0/-9999999/
  save

! Mix sync tone to baseband, low-pass filter, downsample to 1378.125 Hz
  dt00=dt
  call timer('filbig  ',0)
  call filbig(dd,npts,f0,newdat,cx,n5,sq0)
  call timer('filbig  ',1)

! NB: cx has sample rate 12000*77125/672000 = 1378.125 Hz

! Find best DF, f1, f2, and DT.  Start by downsampling to 344.53125 Hz
  call timer('fil6521 ',0)
! Add some zeros at start of c5 arrays -- empirical fix for negative DT's
  nadd=1089
  c5x(:nadd)=0.
  call fil6521(cx,n5,c5x(nadd+1),n6)
  n6=n6+nadd
  call timer('fil6521 ',1)

  fsample=1378.125/4.
  a(5)=dt00
  i0=nint((a(5)+0.5)*fsample) - 2 + nadd
  if(i0.lt.1) then
!     write(23,*) 'i0 too small in decode1a:',i0,f0,a(5),fsample,nadd
!     flush(23)
     i0=1
  endif
  nz=n6+1-i0

! We're looking only at sync tone here... so why not downsample by another
! factor of 1/8, say?  Should be a significant execution speed-up.
  call timer('afc65b  ',0)
! Best fit for DF, f1, and f2
  call afc65b(c5x(i0),nz,fsample,nflip,a,ccfbest,dtbest)
  call timer('afc65b  ',1)

  sync2=3.7e-4*ccfbest/sq0                    !Constant is empirical 

! Apply AFC corrections to the time-domain signal
! Now we are back to using the 1378.125 Hz sample rate, enough to 
! accommodate the full JT65C bandwidth.

  call timer('twkfreq ',0)
  call twkfreq65(cx,n5,a)
  call timer('twkfreq ',1)

! Compute spectrum for each half symbol.
! Adding or subtracting a small number (e.g., 5) to j may make it decode.\
! NB: might want to try computing full-symbol spectra (nfft=512, even for
! submodes B and C).

  nsym=126
  nfft=512
  j=(dt00+dtbest+2.685)*1378.125
  if(j.lt.0) j=0

  call timer('sh_ffts ',0)
  do k=1,nsym
     do i=1,nfft
        j=j+1
        c5a(i)=cx(j)
     enddo
     call four2a(c5a,nfft,1,1,1)
     do i=1,66
        jj=i
        if(mode65.eq.2) jj=2*i-1
        if(mode65.eq.4) jj=4*i-3
        s2(i,k)=real(c5a(jj))**2 + aimag(c5a(jj))**2
     enddo
  enddo
  call timer('sh_ffts ',1)

  call timer('dec65b  ',0)
  call decode65b(s2,nflip,mode65,nqd,nbmkv,nhist,decoded)
  dt=dt00 + dtbest + 1.7
  call timer('dec65b  ',1)

  return
end subroutine decode65a
