subroutine downsam9(id2,npts8,nsps8,newdat,nspsd,fpk,c2,nz2)

!Downsample from id2() into c2() so as to yield nspsd samples per symbol, 
!mixing from fpk down to zero frequency.  The downsample factor is 432.

  use, intrinsic :: iso_c_binding
  use FFTW3

  include 'constants.f90'
  parameter (NMAX1=604800)
  type(C_PTR) :: plan                        !Pointers plan for big FFT
  integer*2 id2(0:8*npts8-1)
  real*4 x1(0:NMAX1-1)
  complex c1(0:NMAX1/2)
  complex c2(0:1440-1)
  real s(5000)
  logical first
  common/patience/npatience,nthreads
  data first/.true./
  save plan,first,c1,s

  nfft1=NMAX1                                !Forward FFT length
  df1=12000.0/nfft1
  npts=8*npts8

  if(newdat.eq.1) then
     fac=6.963e-6                            !Why this weird constant?
     do i=0,npts-1
        x1(i)=fac*id2(i)
     enddo
     x1(npts:nfft1-1)=0.                      !Zero the rest of x1
  endif

  if(first) then
     nflags=FFTW_ESTIMATE
     if(npatience.eq.1) nflags=FFTW_ESTIMATE_PATIENT
     if(npatience.eq.2) nflags=FFTW_MEASURE
     if(npatience.eq.3) nflags=FFTW_PATIENT
     if(npatience.eq.4) nflags=FFTW_EXHAUSTIVE
! Plan the FFTs just once

     !$omp critical(fftw) ! serialize non thread-safe FFTW3 calls
     call fftwf_plan_with_nthreads(nthreads)
     plan=fftwf_plan_dft_r2c_1d(nfft1,x1,c1,nflags)
     call fftwf_plan_with_nthreads(1)
     !$omp end critical(fftw)

     first=.false.
  endif

  if(newdat.eq.1) then
     fac=6.963e-6                             !Why this weird constant?
     do i=0,npts-1
        x1(i)=fac*id2(i)
     enddo
     x1(npts:nfft1-1)=0.                      !Zero the rest of x1
     call timer('FFTbig9 ',0)
     call fftwf_execute_dft_r2c(plan,x1,c1)
     call timer('FFTbig9 ',1)

     nadd=int(1.0/df1)
     s=0.
     do i=1,5000
        j=int((i-1)/df1)
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
  i0=int(fpk/df1)

  nw=100
  ia=max(1,nf-nw)
  ib=min(5000,nf+nw)
  call pctile(s(ia),ib-ia+1,40,avenoise)

  fac=sqrt(1.0/avenoise)
  do i=0,nfft2-1
     j=i0+i
     if(i.gt.nh2) j=j-nfft2
     c2(i)=fac*c1(j)
  enddo
  call four2a(c2,nfft2,1,1,1)              !FFT back to time domain
  nz2=8*npts8/ndown

  return
end subroutine downsam9
