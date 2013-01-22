subroutine slope(y,npts,xpk)

! Remove best-fit slope from data in y(i).  When fitting the straight line,
! ignore the peak around xpk +/- 2.

  real y(npts)
  real x(100)

  do i=1,npts
     x(i)=i
  enddo

  sumw=0.
  sumx=0.
  sumy=0.
  sumx2=0.
  sumxy=0.
  sumy2=0.

  do i=1,npts
     if(abs(i-xpk).gt.2.0) then
        sumw=sumw + 1.0
        sumx=sumx + x(i)
        sumy=sumy + y(i)
        sumx2=sumx2 + x(i)**2
        sumxy=sumxy + x(i)*y(i)
        sumy2=sumy2 + y(i)**2
     endif
  enddo

  delta=sumw*sumx2 - sumx**2
  a=(sumx2*sumy - sumx*sumxy) / delta
  b=(sumw*sumxy - sumx*sumy) / delta

  do i=1,npts
     y(i)=y(i)-(a + b*x(i))
  enddo

  return
end subroutine slope
