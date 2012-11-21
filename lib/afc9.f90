subroutine afc9(cx,npts,nfast,fsample,nflip,ipol,xpol,           &
     ndphi,iloop,a,ccfbest,dtbest)

  logical xpol
  complex cx(npts)
  real a(3),deltaa(3)

  a(1)=0.                                   !f0
  a(2)=0.                                   !f1
  a(3)=0.                                   !f2
  deltaa(1)=2.0
  deltaa(2)=2.0
  deltaa(3)=2.0
  nterms=3

! Start the iteration
  chisqr=0.
  chisqr0=1.e6
  do iter=1,3                               !One iteration is enough?
     do j=1,nterms
        chisq1=fchisq(cx,npts,nfast,fsample,nflip,a,ccfmax,dtmax)
        fn=0.
        delta=deltaa(j)
10      a(j)=a(j)+delta
        chisq2=fchisq(cx,npts,nfast,fsample,nflip,a,ccfmax,dtmax)
        if(chisq2.eq.chisq1) go to 10
        if(chisq2.gt.chisq1) then
           delta=-delta                      !Reverse direction
           a(j)=a(j)+delta
           tmp=chisq1
           chisq1=chisq2
           chisq2=tmp
        endif
20      fn=fn+1.0
        a(j)=a(j)+delta
        chisq3=fchisq(cx,npts,nfast,fsample,nflip,a,ccfmax,dtmax)
        if(chisq3.lt.chisq2) then
           chisq1=chisq2
           chisq2=chisq3
           go to 20
        endif

! Find minimum of parabola defined by last three points
        delta=delta*(1./(1.+(chisq1-chisq2)/(chisq3-chisq2))+0.5)
        a(j)=a(j)-delta
        deltaa(j)=deltaa(j)*fn/3.
     enddo
     chisqr=fchisq(cx,npts,nfast,fsample,nflip,a,ccfmax,dtmax)
     if(chisqr/chisqr0.gt.0.9999) go to 30
     chisqr0=chisqr
  enddo

30 ccfbest=ccfmax * (1378.125/fsample)**2
  dtbest=dtmax

  return
end subroutine afc9
