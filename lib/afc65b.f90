subroutine afc65b(cx,npts,fsample,nflip,a,ccfbest,dtbest)

! Find delta f, f1, f2 ==> a(1:3)

  complex cx(npts)
  real a(5),deltaa(5)

  a(1)=0.
  a(2)=0.
  a(3)=0.
  a(4)=0.
  deltaa(1)=2.0
  deltaa(2)=2.0
  deltaa(3)=2.0
  deltaa(4)=0.05
  nterms=3                                  !Maybe 2 is enough?

!  Start the iteration
  chisqr=0.
  chisqr0=1.e6
  do iter=1,3                               !One iteration is enough?
     do j=1,nterms
        chisq1=fchisq65(cx,npts,fsample,nflip,a,ccfmax,dtmax)
        fn=0.
        delta=deltaa(j)
10      a(j)=a(j)+delta
        chisq2=fchisq65(cx,npts,fsample,nflip,a,ccfmax,dtmax)
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
        chisq3=fchisq65(cx,npts,fsample,nflip,a,ccfmax,dtmax)
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
     chisqr=fchisq65(cx,npts,fsample,nflip,a,ccfmax,dtmax)
     if(chisqr/chisqr0.gt.0.9999) go to 30
     chisqr0=chisqr
  enddo

30 ccfbest=ccfmax * (1378.125/fsample)**2
  dtbest=dtmax

  return
end subroutine afc65b
