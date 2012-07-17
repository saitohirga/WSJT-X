subroutine hipass(y,npts,nwidth)

!  Hipass filter for time-domain data.  Removes an RC-type running 
!  mean (time constant nwidth) from array y(1:npts).  

  real y(npts)

  c1=1.0/nwidth
  c2=1.0-c1
  s=0.
  do i=1,nwidth                      !Get initial average
     s=s+y(i)
  enddo
  ave=c1*s

  do i=1,npts                        !Do the filtering
     y0=y(i)
     y(i)=y0-ave                     !Remove the mean
     ave=c1*y0 + c2*ave              !Update the mean
  enddo

return
end subroutine hipass
