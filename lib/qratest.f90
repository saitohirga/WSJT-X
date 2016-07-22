program qratest

  parameter (NMAX=60*12000) 
  real dd(NMAX)
  real t(5)
  integer*8 count0,count1,clkfreq
  character*8 arg

  nargs=iargc()
  if(nargs.ne.2) then
     print*,'Usage: qratest f0 fTol'
     go to 999
  endif
  call getarg(1,arg)
  read(arg,*) nf0
  call getarg(2,arg)
  read(arg,*) ntol
  nf1=nf0-ntol
  nf2=nf0+ntol

  do n=1,999
     read(60,end=999) dd
     call system_clock(count0,clkfreq)
     call sync64(dd,nf1,nf2,dtx,f0,f01,f02,f03,snr,t)
     call system_clock(count1,clkfreq)
     tsec=float(count1-count0)/float(clkfreq)
!     nf0=200*nint(f0/200.)
     dfreq0=f0-nf0
     dfreq1=f01-nf0
     dfreq2=f02-nf0
     dfreq3=f03-nf0
     write(*,1000) dtx,f0,dfreq0,dfreq1,dfreq2,dfreq3,snr,tsec,t(1),t(2)
1000 format(f8.3,f8.2,4f7.2,f8.1,3f6.3)
  enddo

999 end program qratest

subroutine sync64(dd,nf1,nf2,dtx,f0,f01,f02,f03,snr,t)
  parameter (NMAX=60*12000)                  !Max size of raw data at 12000 Hz
  parameter (NSPS=2304)                      !Samples per symbol at 4000 Hz
  parameter (NSPC=7*NSPS)                    !Samples per Costas array
  real dd(NMAX)                              !Raw data
  real x(672000)                             !Up to 56 s at 12000 Hz
  real t(5)

  real s0(0:NSPC-1)
  real s1(0:NSPC-1)
  real s2(0:NSPC-1)
  real s3(0:NSPC-1)

  real s0a(0:NSPC-1)
  real s1a(0:NSPC-1)
  real s2a(0:NSPC-1)
  real s3a(0:NSPC-1)

  integer*8 count0,count1,clkfreq
  integer icos7(0:6)
  integer ipk(1)

  complex cc(0:NSPC-1)
  complex c0(0:336000)
  complex c1(0:NSPC-1)
  complex c2(0:NSPC-1)
  complex c3(0:NSPC-1)
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
  call system_clock(count0,clkfreq)
  call four2a(c0,nfft1,1,-1,0)             !Forward r2c FFT
  call four2a(c0,nfft2,1,1,1)              !Inverse c2c FFT; c0 is analytic sig
  call system_clock(count1,clkfreq)
  t(1)=float(count1-count0)/float(clkfreq)
  npts2=npts0/3                            !Downsampled complex data length
  nfft3=NSPC
  nh3=nfft3/2
  df3=4000.0/nfft3
  ia=nint(nf1/df3)
  ib=nint(nf2/df3)
  iz=ib-ia+1
  smax=0.
  jpk=0
  s0=0.
  ja=0
  jb=6*4000
  jstep=200
  call system_clock(count0,clkfreq)
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
        do i=ia,ib
           freq=i*df3
           s1(i)=real(c1(i))**2 + aimag(c1(i))**2
           s2(i)=real(c2(i))**2 + aimag(c2(i))**2
           s3(i)=real(c3(i))**2 + aimag(c3(i))**2
        enddo
        call smo121(s1(ia:ib),iz)
        call smo121(s2(ia:ib),iz)
        call smo121(s3(ia:ib),iz)
        s0(ia:ib)=s1(ia:ib) + s2(ia:ib) + s3(ia:ib)
        s=maxval(s0(ia:ib))
        if(s.gt.smax) then
           jpk=j1
           s0a=s0
           s1a=s1
           s2a=s2
           s3a=s3
           smax=s
           dtx=jpk/4000.0 - 1.0
           ipk=maxloc(s0(ia:ib))
           f0=(ipk(1)+ia-1)*df3

           ipk=maxloc(s1(ia:ib))
           f01=(ipk(1)+ia-1)*df3

           ipk=maxloc(s2(ia:ib))
           f02=(ipk(1)+ia-1)*df3

           ipk=maxloc(s3(ia:ib))
           f03=(ipk(1)+ia-1)*df3
        endif
     enddo
     ja=jpk-2*jstep
     jb=jpk+2*jstep
     jstep=10
  enddo
  call system_clock(count1,clkfreq)
  t(2)=float(count1-count0)/float(clkfreq)

  ave=sum(s0a(ia:ib))/iz
  sq=dot_product(s0a(ia:ib),s0a(ia:ib))
  rms=sqrt(sq/iz - ave*ave)
  snr=(smax-ave)/rms

!  do i=0,nfft3-1
!     freq=i*df3
!     if(freq.gt.2500.0) exit
!     write(14,1020) freq,s0a(i),s1a(i),s2a(i),s3a(i)
!1020 format(f10.3,4f12.1)
!  enddo
        
end subroutine sync64
