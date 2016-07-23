subroutine sync64(dd,nf1,nf2,nfqso,ntol,maxf1,dtx,f0,kpk,snrdb,s3a)

  parameter (NMAX=60*12000)                  !Max size of raw data at 12000 Hz
  parameter (NSPS=2304)                      !Samples per symbol at 4000 Hz
  parameter (NSPC=7*NSPS)                    !Samples per Costas array
  real dd(NMAX)                              !Raw data
  real x(672000)                             !Up to 56 s at 12000 Hz
  real s3a(0:63,1:63)                        !Synchronized symbol spectra
  real s1(0:NSPC-1)                          !Power spectrum of Costas 1
  real s2(0:NSPC-1)                          !Power spectrum of Costas 2
  real s3(0:NSPC-1)                          !Power spectrum of Costas 3
  real s0(0:NSPC-1)                          !Sum of s1+s2+s3
  real s0a(0:NSPC-1)                         !Best synchromized spectrum
  integer icos7(0:6)                         !Costas 7x7 tones
  integer ipk0(1)
  complex cc(0:NSPC-1)                       !Costas waveform
  complex c0(0:336000)                       !Complex spectrum of dd()
  complex c1(0:NSPC-1)                       !Complex spectrum of Costas 1
  complex c2(0:NSPC-1)                       !Complex spectrum of Costas 2
  complex c3(0:NSPC-1)                       !Complex spectrum of Costas 3
  logical first
  equivalence (x,c0)
  data icos7/2,5,6,0,4,1,3/                  !Costas 7x7 tone pattern
  data first/.true./
  save

  if(first) then
     twopi=8.0*atan(1.0)
     dfgen=12000.0/6912.0
     k=-1
     phi=0.
     do j=0,6                               !Compute complex Costas waveform
        dphi=twopi*icos7(j)*dfgen/4000.0
        do i=1,2304
           phi=phi + dphi
           if(phi.gt.twopi) phi=phi-twopi
           k=k+1
           cc(k)=cmplx(cos(phi),sin(phi))
        enddo
     enddo
     first=.false.
  endif

  npts0=54*12000
  nfft1=672000
  nfft2=nfft1/3
  df1=12000.0/nfft1
  fac=2.0/nfft1
  x=fac*dd(1:nfft1)
  call four2a(c0,nfft1,1,-1,0)             !Forward r2c FFT
  call four2a(c0,nfft2,1,1,1)              !Inverse c2c FFT; c0 is analytic sig
  npts2=npts0/3                            !Downsampled complex data length
  nfft3=NSPC
  nh3=nfft3/2
  df3=4000.0/nfft3
  fa=max(nf1,nfqso-ntol)
  fb=min(nf2,nfqso+ntol)
  ia=max(maxf1,nint(fa/df3))
  ib=min(NSPC-1-maxf1,nint(fb/df3))
  iz=ib-ia+1
  snr=0.
  jpk=0
  ja=0
  jb=6*4000
  jstep=200
  ka=-maxf1
  kb=maxf1
  ipk=0
  kpk=0
  do iter=1,2
     do j1=ja,jb,jstep
        j2=j1 + 39*2304
        j3=j1 + 77*2304
        c1=1.e-4*c0(j1:j1+NSPC-1) * conjg(cc)
        call four2a(c1,nfft3,1,-1,1)
        c2=1.e-4*c0(j2:j2+NSPC-1) * conjg(cc)
        call four2a(c2,nfft3,1,-1,1)
        c3=1.e-4*c0(j3:j3+NSPC-1) * conjg(cc)
        call four2a(c3,nfft3,1,-1,1)
        s0=0.
        s1=0.
        s2=0.
        s3=0.
        do i=ia,ib
           freq=i*df3
           s1(i)=real(c1(i))**2 + aimag(c1(i))**2
           s2(i)=real(c2(i))**2 + aimag(c2(i))**2
           s3(i)=real(c3(i))**2 + aimag(c3(i))**2
        enddo
        do k=ka,kb
           s0(ia:ib)=s1(ia-k:ib-k) + s2(ia:ib) + s3(ia+k:ib+k)
           call smo121(s0(ia:ib),iz)
           call averms(s0(ia:ib),iz,14,ave,rms)
           s=(maxval(s0(ia:ib))-ave)/rms
           if(s.gt.snr) then
              jpk=j1
              s0a=s0
              snr=s
              dtx=jpk/4000.0 - 1.0
              ipk0=maxloc(s0(ia:ib))
              ipk=ipk0(1)
              f0=(ipk+ia-1)*df3
              kpk=k
           endif
        enddo
     enddo
     ja=jpk-2*jstep
     jb=jpk+2*jstep
     jstep=10
!     ka=kpk
!     kb=kpk
  enddo
  snrdb=10.0*log10(snr)-39.0

!###
! Now use tweak on the c0() array, then do nfft4=NSPS FFTs to get s3a(), 
! the properly synchronized symbol spectra.

  return
end subroutine sync64
