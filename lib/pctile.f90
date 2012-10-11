subroutine pctile(x,npts,npct,xmedian)

  real x(npts)
  integer hist(0:1000)

  ave=sum(x)/npts
  hist=0
  do i=1,npts
     j=nint(100.0*x(i)/ave)
     if(j.lt.0) j=0
     if(j.gt.1000) j=1000
     hist(j)=hist(j)+1
  enddo

  nsum=0
  ntest=nint(npts*float(npct)/100.0)
  do j=0,1000
     nsum=nsum+hist(j)
     if(nsum.ge.ntest) exit
  enddo

  xmedian=j*ave/100.0

  return
end subroutine pctile
