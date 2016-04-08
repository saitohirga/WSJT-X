subroutine refspectrum(id2,brefspec)

! Input:
!  id2       i*2        Raw 16-bit integer data, 12000 Hz sample rate
!  brefspec  logical    True when accumulating a reference spectrum

  integer*2 id2(3456)
  logical brefspec

!  write(*,3001) id2(1:10),brefspec
!3001 format(10i5,L8)

  return
end subroutine refspectrum
