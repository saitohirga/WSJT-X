subroutine afc9(c3,npts,fsample,a,syncpk)

  complex c3(0:npts-1)
  real a(3),deltaa(3)

  a(1)=0.                                   !f0
  a(2)=0.                                   !f1
  a(3)=0.                                   !f2
  deltaa(1)=0.2
  deltaa(2)=0.01
  deltaa(3)=0.01
  nterms=3

! Start the iteration
  chisqr=0.
  chisqr0=1.e6
  do iter=1,4                               !One iteration is enough?
     do j=1,nterms
        chisq1=fchisq(c3,npts,fsample,a)
        fn=0.
        delta=deltaa(j)
10      a(j)=a(j)+delta
        chisq2=fchisq(c3,npts,fsample,a)
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
        chisq3=fchisq(c3,npts,fsample,a)
        if(chisq3.lt.chisq2) then
           chisq1=chisq2
           chisq2=chisq3
           go to 20
        endif

! Find minimum of parabola defined by last three points
        delta=delta*(1./(1.+(chisq1-chisq2)/(chisq3-chisq2))+0.5)
        a(j)=a(j)-delta
        deltaa(j)=deltaa(j)*fn/3.
!        write(*,4000) iter,j,a,deltaa,-chisq2
!4000    format(i1,i2,6f10.4,f9.3)
     enddo
     chisqr=fchisq(c3,npts,fsample,a)
     if(chisqr/chisqr0.gt.0.9999) exit
     chisqr0=chisqr
  enddo

  syncpk=-chisqr
!  write(*,4001) a,deltaa,-chisq2
!4001 format(3x,6f10.4,f9.3)

  return
end subroutine afc9
