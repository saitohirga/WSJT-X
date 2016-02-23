subroutine degrade_snr(d2,npts,db,bw)

  integer*2 d2(npts)
  real dat(60*12000)

  dat(1:npts)=d2
  p0=dot_product(dat(1:npts),dat(1:npts))/npts
  if(bw.gt.0.0) p0=p0*6000.0/bw
  s=sqrt(p0*(10.0**(0.1*db) - 1.0))
  do i=1,npts
     d2(i)=nint(dat(i) + s*gran())
  enddo
  
!  dat(1:npts)=d2
!  p1=dot_product(dat(1:npts),dat(1:npts))/npts
!  if(bw.gt.0.0) p1=p1*6000.0/bw
!  write(*,3001) db,bw,p0,s,10.0*log10(p1/p0)
!3001 format(5f10.3)

  return
end subroutine degrade_snr

  
