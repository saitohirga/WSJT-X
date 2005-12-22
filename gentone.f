      subroutine gentone(x,n,k)

      real*4 x(512)

      dt=1.0/11025.0
      f=(n+51)*11025.0/512.0
      do i=1,512
         x(i)=sin(6.2831853*i*dt*f)
      enddo
      k=k+512

      return
      end
