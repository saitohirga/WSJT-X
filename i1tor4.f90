
!--------------------------------------------------- i1tor4
subroutine i1tor4(d,jz,data)

!  Convert wavefile byte data from to real*4.

  integer*1 d(jz)
  real data(jz)
  integer*1 i1
  equivalence(i1,i4)

  do i=1,jz
     n=d(i)
     i4=n-128
     data(i)=i1
  enddo

  return
end subroutine i1tor4
