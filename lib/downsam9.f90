subroutine downsam9(id2,npts8,nsps8,newdat,nspsd,fpk,c2,nz2)

!Downsample from id2() into C2() so as to yield nspsd samples per symbol, 
!mixing from fpk down to zero frequency.

  include 'constants.f90'
  parameter (NMAX1=1024*1920)
  integer*2 id2(0:8*npts8-1)
  real*4 x1(0:NMAX1-1)
  complex c1(0:NMAX1/2)
  complex c2(0:4096-1)
  real s(5000)
  equivalence (c1,x1)
  save

  nfft1=1024*nsps8                          !Forward FFT length
  df1=12000.0/nfft1
  npts=8*npts8

  if(newdat.eq.1) then
     fac=6.963e-6                             !Why this weird constant?
     do i=0,npts-1
        x1(i)=fac*id2(i)
     enddo
     x1(npts:nfft1-1)=0.                      !Zero the rest of x1
     call timer('fft_forw',0)
     call four2a(c1,nfft1,1,-1,0)             !Forward FFT, r2c
     call timer('fft_forw',1)

     nadd=1.0/df1
     s=0.
     do i=1,5000
        j=(i-1)/df1
        do n=1,nadd
           j=j+1
           s(i)=s(i)+real(c1(j))**2 + aimag(c1(j))**2
        enddo
     enddo
  endif

  ndown=8*nsps8/nspsd                      !Downsample factor
  nfft2=nfft1/ndown                        !Backward FFT length
  nh2=nfft2/2
  nf=nint(fpk)
  i0=fpk/df1

  nw=100
  ia=max(1,nf-nw)
  ib=min(5000,nf+nw)
  call timer('pctile_1',0)
  call pctile(s(ia),ib-ia+1,40,avenoise)
  call timer('pctile_1',1)

  fac=sqrt(1.0/avenoise)
  do i=0,nfft2-1
     j=i0+i
     if(i.gt.nh2) j=j-nfft2
     c2(i)=fac*c1(j)
  enddo
  call timer('fft_back',0)
  call four2a(c2,nfft2,1,1,1)              !FFT back to time domain
  call timer('fft_back',1)
  nz2=8*npts8/ndown

  return
end subroutine downsam9
