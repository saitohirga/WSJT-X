subroutine chkss2(ss2,freq,drift,schk)

  real ss2(0:8,85)
  real s(0:8,85)
  real s1(0:5)
  include 'jt9sync.f90'

  ave=sum(ss2)/(9*85)
  s=ss2/ave-1.0

!  call zplot9(s,freq,drift)
  s1=0.
  do lag=0,5
     do i=1,16
        j=ii(i)+lag
        if(j.le.85) s1(lag)=s1(lag) + s(0,j)
     enddo
  enddo
  schk=s1(0)/16.0

  return
end subroutine chkss2

