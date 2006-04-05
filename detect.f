      subroutine detect(data,npts,f,y)

C  Compute powers at the tone frequencies using 1-sample steps.

      parameter (NZ=11025,NSPD=25)
      real data(npts)
      real y(npts)
      complex c(NZ)
      complex csum
      data twopi/6.283185307/

      dpha=twopi*f/11025.0
      do i=1,npts
         c(i)=data(i)*cmplx(cos(dpha*i),-sin(dpha*i))
      enddo

      csum=0.
      do i=1,NSPD
         csum=csum+c(i)
      enddo
         
      y(1)=real(csum)**2 + aimag(csum)**2
      do i=2,npts-(NSPD-1)
         csum=csum-c(i-1)+c(i+NSPD-1)
         y(i)=real(csum)**2 + aimag(csum)**2
      enddo

      return
      end
