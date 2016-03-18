!program smolorentz
subroutine smolorentz(s1,nz,w,s2)

!  parameter (nz=512)
  real s1(nz),s2(nz)
  real y(-50:50)
!  character*8 arg

!  s1=0.
!  s1(256)=1.

!  call getarg(1,arg)
!  read(arg,*) w
  
  do i=-50,50
     x=i
     z=x/(0.5*w)
     y(i)=0.
     if(abs(z).lt.3.0) then
        d=1.0 + z*z
        y(i)=(1.0/d - 0.1)*10.0/9.0
     endif
  enddo

  jz=nint(1.5*w)
  if(jz.gt.50) jz=50
  do i=1,nz
     s=0.
     sy=0.
     do j=-jz,jz
        k=i+j
        if(k.ge.1 .and. k.le.nz) then
           s=s + s1(k)*y(j)
           sy=sy+y(j)
        endif
     enddo
     s2(i)=s/sy
!     write(52,3002) i-256,s1(i),s2(i)
!3002 format(i5,2f10.4)
  enddo

end subroutine smolorentz
