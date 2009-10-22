      subroutine four2a(a,nfft,ndim,isign,iform)

C     IFORM = 1, 0 or -1, as data is
C     complex, real, or the first half of a complex array.  Transform
C     values are returned in array DATA.  They are complex, real, or
C     the first half of a complex array, as IFORM = 1, -1 or 0.

C     The transform of a real array (IFORM = 0) dimensioned N(1) by N(2)
C     by ... will be returned in the same array, now considered to
C     be complex of dimensions N(1)/2+1 by N(2) by ....  Note that if
C     IFORM = 0 or -1, N(1) must be even, and enough room must be
C     reserved.  The missing values may be obtained by complex conjuga-
C     tion.  

C     The reverse transformation of a half complex array dimensioned
C     N(1)/2+1 by N(2) by ..., is accomplished by setting IFORM
C     to -1.  In the N array, N(1) must be the true N(1), not N(1)/2+1.
C     The transform will be real and returned to the input array.

      parameter (NPMAX=100)
      parameter (NSMALL=16384)
      complex a(nfft)
      complex aa(NSMALL)
      integer nn(NPMAX),ns(NPMAX),nf(NPMAX),nl(NPMAX)
      real*8 plan(NPMAX)             !Actually should be i*8, but no matter
      data nplan/0/
      include 'fftw3.f'
      save plan,nplan,nn,ns,nf,nl

      if(nfft.lt.0) go to 999

      nloc=loc(a)
      do i=1,nplan
         if(nfft.eq.nn(i) .and. isign.eq.ns(i) .and.
     +      iform.eq.nf(i) .and. nloc.eq.nl(i)) go to 10
      enddo
      if(nplan.ge.NPMAX) stop 'Too many FFTW plans requested.'
      nplan=nplan+1
      i=nplan
      nn(i)=nfft
      ns(i)=isign
      nf(i)=iform
      nl(i)=nloc

C  Planning: FFTW_ESTIMATE, FFTW_ESTIMATE_PATIENT, FFTW_MEASURE, 
C            FFTW_PATIENT,  FFTW_EXHAUSTIVE
C  NB: "EXHAUSTIVE" takes more or less forever, for long transforms.
      npatience=1
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
      call sleep_msec(0)
      if(isign.eq.-1 .and. iform.eq.1) then
         call sfftw_plan_dft_1d_(plan(i),nfft,a,a,
     +        FFTW_FORWARD,nflags)
      else if(isign.eq.1 .and. iform.eq.1) then
         call sfftw_plan_dft_1d_(plan(i),nfft,a,a,
     +        FFTW_BACKWARD,nflags)
      else if(isign.eq.-1 .and. iform.eq.0) then
         call sfftw_plan_dft_r2c_1d_(plan(i),nfft,a,a,nflags)
      else if(isign.eq.1 .and. iform.eq.-1) then
         call sfftw_plan_dft_c2r_1d_(plan(i),nfft,a,a,nflags)
      else
         stop 'Unsupported request in four2a'
      endif
      call sleep_msec(0)
      i=nplan
      if(nfft.le.NSMALL) then
         jz=nfft
         if(iform.eq.0) jz=nfft/2
         do j=1,jz
            a(j)=aa(j)
         enddo
      endif

 10   continue
      call sleep_msec(0)
      call sfftw_execute_(plan(i))
      call sleep_msec(0)
      return

 999  do i=1,nplan
         call sfftw_destroy_plan_(plan(i))
      enddo

      return
      end
