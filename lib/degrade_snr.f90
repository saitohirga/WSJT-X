subroutine degrade_snr(d2,npts,db)

  integer*2 d2(npts)
  real dat(60*12000)

  dat(1:npts)=d2
  p0=dot_product(dat(1:npts),dat(1:npts))/npts
  s=sqrt(p0*(10.0**(0.1*db) - 1.0))
  do i=1,npts
     d2(i)=nint(dat(i) + s*gran())
  enddo
  
!  dat(1:npts)=d2
!  p1=dot_product(dat(1:npts),dat(1:npts))/npts
!  print*,db,p0,s,10.0*log10(p1/p0)

  return
end subroutine degrade_snr

  
