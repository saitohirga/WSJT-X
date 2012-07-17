subroutine mskdf(cdat,npts,t2,nfft1,f0,nfreeze,mousedf,ntol,dfx,snrsq2)

! Determine DF for a JTMS signal.  Also find ferr, a measure of
! frequency differerence between 1st and 2nd harmonic.  
! (Should be 0.000)

  parameter (NZ=128*1024)
  complex cdat(npts)
  integer ntol
  real sq(NZ)
  real ccf(-2600:2600)                  !Correct limits?
  real tmp(NZ)
  complex c(NZ)
  data nsps/8/
  save c

  df1=48000.0/nfft1
  nh=nfft1/2
  fac=1.0/(nfft1**2)

  do i=1,npts
     c(i)=fac*cdat(i)**2
  enddo
  c(npts+1:nfft1)=0.
  call four2a(c,nfft1,1,-1,1)

! In the "doubled-frequencies" spectrum of squared cdat:
  fa=2.0*(f0-400)
  fb=2.0*(f0+400)
  j0=nint(2.0*f0/df1)
  ja=nint(fa/df1)
  jb=nint(fb/df1)
  jd=nfft1/nsps

  do j=1,nh+1
     sq(j)=real(c(j))**2 + aimag(c(j))**2
!     if(j*df1.lt.6000.0) write(54,3009) j*df1,sq(j),db(sq(j))
!3009 format(3f12.3)
  enddo

  ccf=0.
  do j=ja,jb
     ccf(j-j0-1)=sq(j)+sq(j+jd)
  enddo

  call pctile(ccf(ja-j0-1),tmp,jb-ja+1,50,base)
  ccf=ccf/base

  if(NFreeze.gt.0) then
     fa=2.0*(f0+MouseDF-ntol)
     fb=2.0*(f0+MouseDF+ntol)
  endif  
  ja=nint(fa/df1)
  jb=nint(fb/df1)

!  rewind 51
  smax=0.
  do j=ja,jb
     k=j-j0-1
     if(ccf(k).gt.smax) then
        smax=ccf(k)
        jpk=j
     endif
     f=0.5*k*df1
!     write(51,3002) f,ccf(k)
!3002 format(2f12.3)
  enddo
!  call flush(51)

  fpk=(jpk-1)*df1  
  dfx=0.5*fpk-f0
  snrsq2=smax

  return
end subroutine mskdf
