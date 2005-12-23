
!------------------------------------------------- hscroll
subroutine hscroll(a,nx)
  integer*2 a(750,300)

  do j=1,150
     do i=1,750
        if(nx.gt.50) a(i,150+j)=a(i,j)
        a(i,j)=0
     enddo
  enddo
  return

end subroutine hscroll
