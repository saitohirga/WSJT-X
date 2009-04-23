subroutine pix2d65(d2,jz)

! Compute data for green line in JT65 mode.

  integer*2 d2(jz)            !Raw input data
  include 'gcom2.f90'

  sum=0.
  do i=1,jz
     sum=sum+d2(i)
  enddo
  nave=nint(sum/jz)
  nadd=nint(53.0*11025.0/500.0)
  ngreen=min(jz/nadd,500)
  k=0
  do i=1,ngreen
     sq=0.
     do n=1,nadd
        k=k+1
        d2(k)=d2(k)-nave
        x=d2(k)
        sq=sq + x*x
     enddo
     green(i)=db(sq)-96.0
  enddo

  return
end subroutine pix2d65
