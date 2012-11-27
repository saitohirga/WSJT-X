subroutine downsam9(c0,npts8,nsps8,nspsd,fpk,c2,nz2)     

!Downsample to nspsd samples per symbol, info centered at fpk

  parameter (NMAX=128*31500)
  complex c0(0:npts8-1)
  complex c1(0:NMAX-1)
  complex c2(0:4096-1)
  real s(1000)

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

  ia=nint(250.0/df1)
  nadd=1.0/df1
  j=250/df1
  s=0.
  do i=1,1000
     do n=1,nadd
        j=j+1
        s(i)=s(i)+real(c1(j))**2 + aimag(c1(j))**2
     enddo
!     write(50,3000) i,(j-nadd/2)*df1,s(i)
!3000 format(i5,2f12.3)
  enddo
  call pctile(s,1000,40,avenoise)
!  write(71,*) avenoise,nadd
!  call flush(50)
!  call flush(71)
  
  ndown=nsps8/16                           !Downsample factor
  nfft2=nfft1/ndown                        !Backward FFT length
  nh2=nfft2/2
   
  fshift=fpk-1500.0
  i0=nh1 + fshift/df1
  fac=1.0/avenoise
  do i=0,nfft2-1
     j=i0+i
     if(i.gt.nh2) j=j-nfft2
     c2(i)=fac*c1(j)
  enddo

  call four2a(c2,nfft2,1,1,1)              !Backward FFT

  nspsd=nsps8/ndown
  nz2=npts8/ndown

  return
end subroutine downsam9
