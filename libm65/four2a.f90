subroutine four2a(a,nfft,ndim,isign,iform)

!     IFORM = 1, 0 or -1, as data is
!     complex, real, or the first half of a complex array.  Transform
!     values are returned in array DATA.  They are complex, real, or
!     the first half of a complex array, as IFORM = 1, -1 or 0.

!     The transform of a real array (IFORM = 0) dimensioned N(1) by N(2)
!     by ... will be returned in the same array, now considered to
!     be complex of dimensions N(1)/2+1 by N(2) by ....  Note that if
!     IFORM = 0 or -1, N(1) must be even, and enough room must be
!     reserved.  The missing values may be obtained by complex conjugation.  

!     The reverse transformation of a half complex array dimensioned
!     N(1)/2+1 by N(2) by ..., is accomplished by setting IFORM
!     to -1.  In the N array, N(1) must be the true N(1), not N(1)/2+1.
!     The transform will be real and returned to the input array.

  parameter (NPMAX=100)
  parameter (NSMALL=16384)
  complex a(nfft)
  complex aa(NSMALL)
  integer nn(NPMAX),ns(NPMAX),nf(NPMAX),nl(NPMAX)
  integer*8 plan(NPMAX)             !Actually should be i*8, but no matter
!  data nplan/0/,npatience/1/
  data nplan/0/,npatience/0/
  include 'fftw3.f'
  save plan,nplan,nn,ns,nf,nl

  if(nfft.lt.0) go to 999

  nloc=loc(a)
  do i=1,nplan
     if(nfft.eq.nn(i) .and. isign.eq.ns(i) .and.                     &
          iform.eq.nf(i) .and. nloc.eq.nl(i)) go to 10
  enddo
  if(nplan.ge.NPMAX) stop 'Too many FFTW plans requested.'
  nplan=nplan+1
  i=nplan
  nn(i)=nfft
  ns(i)=isign
  nf(i)=iform
  nl(i)=nloc

! Planning: FFTW_ESTIMATE, FFTW_ESTIMATE_PATIENT, FFTW_MEASURE, 
!            FFTW_PATIENT,  FFTW_EXHAUSTIVE
  nflags=FFTW_ESTIMATE
  if(npatience.eq.1) nflags=FFTW_ESTIMATE_PATIENT
  if(npatience.eq.2) nflags=FFTW_MEASURE
  if(npatience.eq.3) nflags=FFTW_PATIENT
  if(npatience.eq.4) nflags=FFTW_EXHAUSTIVE

  if(nfft.le.NSMALL) then
     jz=nfft
     if(iform.eq.0) jz=nfft/2
     do j=1,jz
        aa(j)=a(j)
     enddo
  endif
  if(isign.eq.-1 .and. iform.eq.1) then
     call sfftw_plan_dft_1d(plan(i),nfft,a,a,FFTW_FORWARD,nflags)
  else if(isign.eq.1 .and. iform.eq.1) then
     call sfftw_plan_dft_1d(plan(i),nfft,a,a,FFTW_BACKWARD,nflags)
  else if(isign.eq.-1 .and. iform.eq.0) then
     call sfftw_plan_dft_r2c_1d(plan(i),nfft,a,a,nflags)
  else if(isign.eq.1 .and. iform.eq.-1) then
     call sfftw_plan_dft_c2r_1d(plan(i),nfft,a,a,nflags)
  else
     stop 'Unsupported request in four2a'
  endif
  i=nplan
  if(nfft.le.NSMALL) then
     jz=nfft
     if(iform.eq.0) jz=nfft/2
     do j=1,jz
        a(j)=aa(j)
     enddo
  endif

10 continue
  call sfftw_execute(plan(i))
  return

999 do i=1,nplan
! The test is only to silence a compiler warning:
     if(ndim.ne.-999) call sfftw_destroy_plan(plan(i))
  enddo

  return
end subroutine four2a
