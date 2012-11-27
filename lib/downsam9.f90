subroutine downsam9(c0,npts8,nsps8,nspsd,fpk,c2,nz2)     

!Downsample to nspsd samples per symbol, info centered at fpk

  parameter (NMAX=128*31500)
  complex c0(0:npts8-1)
  complex c1(0:NMAX-1)
  complex c2(0:4096-1)

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
  nz2=npts8/ndown

  return
end subroutine downsam9
