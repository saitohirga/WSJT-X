subroutine refspec(id2,k)

! Input:
!  id2       raw 16-bit integer data, 12000 Hz sample rate
!  k         pointer to the most recent new data

! Output (in common/c0com)
!  c0        complex data downsampled to 1500 Hz

  parameter (NMAX=120*12000)         !Total sample intervals per 30 minutes
  integer*2 id2(0:NMAX-1)

!  write(*,3001) id2(k-3456:k-3456+9),k
!3001 format(10i5,i10)

  return
end subroutine refspec
