subroutine test9(c0,npts8,nsps8,fpk,syncpk,snrdb,xdt,freq,drift,i1SoftSymbols)

  parameter (NMAX=128*31500)
  complex c0(0:npts8-1)
  complex c1(0:NMAX-1)
  complex c2(0:4096-1)
  complex c3(0:4096-1)
  complex c5(0:4096-1)
  complex z
  real p(0:3300)
  real a(3),aa(3)
  real ss2(0:8,85)
  real ss3(0:7,69)
  integer*1 i1SoftSymbolsScrambled(207)
  integer*1 i1SoftSymbols(207)
  integer*1 i1
  equivalence (i1,i4)
  character*22 msg

  include 'jt9sync.f90'

  fac=1.e-4
  c1(0:npts8-1)=fac*c0                     !Copy c0 into c1
  do i=1,npts8-1,2
     c1(i)=-c1(i)
  enddo
  c1(npts8:)=0.                            !Zero the rest of c1
  nfft1=128*nsps8                          !Forward FFT length
  nh1=nfft1/2
  df1=1500.0/nfft1
  call four2a(c1,nfft1,1,-1,1)             !Forward FFT

!  do i=0,nfft1-1
!     f=i*df1
!     pp=real(c1(i))**2 + aimag(c1(i))**2
!     write(50,3009) i,f,1.e-6*pp
!3009 format(i8,f12.3,f12.3)
!  enddo   
  
  ndown=nsps8/16                           !Downsample factor
  nfft2=nfft1/ndown                        !Backward FFT length
  nh2=nfft2/2
  
  fshift=fpk-1500.0
  i0=nh1 + fshift/df1
  do i=0,nfft2-1
     j=i0+i
     if(i.gt.nh2) j=j-nfft2
     c2(i)=c1(j)
  enddo

  call four2a(c2,nfft2,1,1,1)              !Backward FFT

  nspsd=nsps8/ndown
  nz=npts8/ndown

! Start of afc loop here: solve for DT, f0, f1, f2, (phi0) ?
  p=0.
  i0=5*nspsd
  do i=0,nz-1
     z=1.e-3*sum(c2(max(i-(nspsd-1),0):i))       !Integrate
     p(i0+i)=real(z)**2 + aimag(z)**2      !Symbol power at freq=0
! Option here for coherent processing ?
!     write(53,3301) i,z,p(i0+i),atan2(aimag(z),real(z))
!3301 format(i6,4e12.3)
  enddo

  call getlags(nsps8,lag0,lag1,lag2)
  tsymbol=nsps8/1500.0
  dtlag=tsymbol/nspsd
  smax=0.
  do lag=lag1,lag2
     sum0=0.
     sum1=0.
     j=-nspsd
     do i=1,85
        j=j+nspsd
        if(isync(i).eq.1) then
           sum1=sum1+p(j+lag)
        else
           sum0=sum0+p(j+lag)
        endif
     enddo
     ss=(sum1/16.0)/(sum0/69.0) - 1.0
     xdt=(lag-lag0)*dtlag
!     write(52,3001) lag,xdt,ss
!3001 format(i5,2f12.3)
     if(ss.gt.smax) then
        smax=ss
        lagpk=lag
     endif
  enddo

  xdt=(lagpk-lag0)*dtlag

  iz=nspsd*85
  do i=0,iz-1
     j=i+lagpk-i0-nspsd+1
     if(j.ge.0 .and. j.le.nz) then
        c3(i)=c2(j)
     else
        c3(i)=0.
     endif
  enddo

  sum1=0.
  sum0=0.
  k=-1
  do i=1,85
     z=0.
     do j=1,nspsd
        k=k+1
        z=z+c3(k)
     enddo
     pp=real(z)**2 + aimag(z)**2     
     if(isync(i).eq.1) then
        sum1=sum1+pp
     else
        sum0=sum0+pp
     endif
  enddo
  ss=(sum1/16.0)/(sum0/69.0) - 1.0

  fsample=1500.0/ndown
  nptsd=nspsd*85
  a=0.
  call afc9(c3,nptsd,fsample,a,syncpk)
  call twkfreq(c3,c5,nptsd,fsample,a)

  aa(1)=-1500.0/nsps8
  aa(2)=0.
  aa(3)=0.
  do i=0,8
     if(i.ge.1) call twkfreq(c5,c5,nptsd,fsample,aa)
     m=0
     k=-1
     do j=1,85
        z=0.
        do n=1,nspsd
           k=k+1
           z=z+c5(k)
        enddo
        ss2(i,j)=real(z)**2 + aimag(z)**2
        if(i.ge.1 .and. isync(j).eq.0) then
           m=m+1
           ss3(i-1,m)=ss2(i,j)
        endif
     enddo
  enddo

!###
  ss=0.
  sig=0.
  do j=1,69
     smax=0.
     do i=0,7
        smax=max(smax,ss3(i,j))
        ss=ss+ss3(i,j)
     enddo
     sig=sig+smax
     ss=ss-smax
  enddo
  ave=ss/(69*7)
  call pctile(ss2,9*85,50,xmed)
  ss3=ss3/ave

  sig=sig/69.
  df8=1500.0/nsps8
  t=max(1.0,sig/xmed - 1.0)
  snrdb=db(t) - db(2500.0/df8) - 5.0
!  print*,'A',ave,xmed,sig,t,df8,snrdb
     
  m0=3
  k=0
  do j=1,69
        smax=0.
        do i=0,7
           if(ss3(i,j).gt.smax) then
              smax=ss3(i,j)
              ipk=i
           endif
        enddo

     do m=m0-1,0,-1                   !Get bit-wise soft symbols
        if(m.eq.2) then
           r1=max(ss3(4,j),ss3(5,j),ss3(6,j),ss3(7,j))
           r0=max(ss3(0,j),ss3(1,j),ss3(2,j),ss3(3,j))
        else if(m.eq.1) then
           r1=max(ss3(2,j),ss3(3,j),ss3(4,j),ss3(5,j))
           r0=max(ss3(0,j),ss3(1,j),ss3(6,j),ss3(7,j))
        else
           r1=max(ss3(1,j),ss3(2,j),ss3(4,j),ss3(7,j))
           r0=max(ss3(0,j),ss3(3,j),ss3(5,j),ss3(6,j))
        endif

        k=k+1
        i4=nint(10.0*(r1-r0))
        if(i4.lt.-127) i4=-127
        if(i4.gt.127) i4=127
        i4=i4+128
        i1SoftSymbolsScrambled(k)=i1
     enddo
  enddo

  call interleave9(i1SoftSymbolsScrambled,-1,i1SoftSymbols)
!  limit=10000
!  call decode9(i1SoftSymbols,limit,nlim,msg)

!###
!  do j=1,85
!     write(71,2101) j,nint(1.e-3*ss2(0:8,j))
!2101 format(i2,2x,9i6)
!  enddo
  
  freq=1500.0 + fshift - a(1)
  drift=a(2)
!  write(*,1100) nutc,nsync,nsnr,xdt,freq,a(2),msg
!1100 format(i4.4,i5,i5,f6.1,f9.2,f8.2,2x,a22)

  return
end subroutine test9
