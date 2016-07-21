program qratest

  parameter (NMAX=60*12000) 
  real dd(NMAX)

  do n=1,999
     read(60,end=999) dd
     call sync64(dd,dtx,f0,snr)
     write(*,1000) dtx,f0,snr
1000 format('DT:',f6.2,'   f0:',f7.1,'   Sync S/N:',f10.1)
  enddo

999 end program qratest

subroutine sync64(dd,dtx,f0,snr)
  parameter (NMAX=60*12000)
  real dd(NMAX)
  real x(672000)

  real s0(0:16127)
  real s1(0:16127)
  real s2(0:16127)
  real s3(0:16127)

  real s0a(0:16127)
  real s1a(0:16127)
  real s2a(0:16127)
  real s3a(0:16127)

  integer icos7(0:6)
  integer ipk(1)

  complex cc(0:16127)
  complex c0(0:336000)
  complex c1(0:16127)
  complex c2(0:16127)
  complex c3(0:16127)
  equivalence (x,c0)
  data icos7/2,5,6,0,4,1,3/                            !Costas 7x7 pattern

  twopi=8.0*atan(1.0)
  dfgen=12000.0/6912.0
  k=-1
  phi=0.
  do j=0,6
     dphi=twopi*icos7(j)*dfgen/4000.0
     do i=1,2304
        phi=phi + dphi
        if(phi.gt.twopi) phi=phi-twopi
        k=k+1
        cc(k)=cmplx(cos(phi),sin(phi))
     enddo
  enddo

  npts0=54*12000
  nfft1=672000
  nfft2=nfft1/3
  df1=12000.0/nfft1
  fac=2.0/nfft1
  x=fac*dd(1:nfft1)
  call four2a(c0,nfft1,1,-1,0)               !Forward r2c FFT

  call four2a(c0,nfft2,1,1,1)                !Inverse c2c FFT
  npts2=npts0/3                              !Downsampled complex data length
  nfft3=16128
  nh3=nfft3/2
  df3=4000.0/nfft3
  iz=750.0/df3
  smax=0.
  jpk=0
  do j1=0,24000,20
     j2=j1 + 39*2304
     j3=j1 + 77*2304
     c1=1.e-4*c0(j1:j1+16127) * conjg(cc)
     call four2a(c1,nfft3,1,-1,1)
     c2=1.e-4*c0(j2:j2+16127) * conjg(cc)
     call four2a(c2,nfft3,1,-1,1)
     c3=1.e-4*c0(j3:j3+16127) * conjg(cc)
     call four2a(c3,nfft3,1,-1,1)
     do i=0,nfft3-1
        freq=i*df3
        s1(i)=real(c1(i))**2 + aimag(c1(i))**2
        s2(i)=real(c2(i))**2 + aimag(c2(i))**2
        s3(i)=real(c3(i))**2 + aimag(c3(i))**2
     enddo
     call smo121(s1,nfft3)
     call smo121(s2,nfft3)
     call smo121(s3,nfft3)
     s0=s1+s2+s3
     s=maxval(s0)
     if(s.gt.smax) then
        jpk=j1
        s0a=s0
        s1a=s1
        s2a=s2
        s3a=s3
        smax=s
        ipk=maxloc(s0)
        dtx=jpk/4000.0 - 1.0
        f0=(ipk(1)-1)*df3
     endif
  enddo

  sq=dot_product(s0a,s0a)
  ave=sum(s0a)/nfft3
  rms=sqrt(sq/nfft3 - ave*ave)
  snr=(smax-ave)/rms

  do i=0,nfft3-1
     freq=i*df3
     if(freq.gt.2500.0) exit
     write(14,1020) freq,s0a(i),s1a(i),s2a(i),s3a(i)
1020 format(f10.3,4f12.1)
  enddo
        
end subroutine sync64
