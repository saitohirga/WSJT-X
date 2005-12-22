subroutine blanker(d2d,jz)

  integer*2 d2d(jz)

  avg=700.
  threshold=5.0
  do i=1,jz
     xmag=abs(d2d(i))
     xmed=0.75*xmed + 0.25*d2d(i)
     avg=0.999*avg + 0.001*xmag
     if(xmag.gt.threshold*avg) then
!        d2d(i)=nint(xmed)
        d2d(i)=0
     endif
  enddo

  return
end subroutine blanker
