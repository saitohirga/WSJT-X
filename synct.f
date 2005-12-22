      subroutine synct(data,jz,jstart,f0,smax)

C  Gets a refined value of jstart.

      parameter (NMAX=30*11025)
      parameter (NB3=3*512)
      real data(jz)
      real*8 dpha,twopi
      complex*16 z,dz
      complex c,c1,zz
      common/hcom/c(NMAX)

      ps(zz)=real(zz)**2 + imag(zz)**2          !Power spectrum function

C  Convert data to baseband (complex result) using quadrature LO.
      twopi=8*atan(1.d0)
      dpha=twopi*f0/11025.d0
      dz=cmplx(cos(dpha),-sin(dpha))
      z=1.d0/dz
      do i=1,jz
         z=z*dz
         c(i)=data(i)*z
      enddo

C  Detect zero-beat sync tone in 512-sample chunks, stepped by 1.
C  Sums replace original values in c(i).

      zz=0
      do i=1,512                      !Compute first sum
         zz=zz+c(i)
      enddo
      c1=c(1)
      c(1)=zz
      do i=2,jz-512                   !Compute the rest recursively
         zz=c(i-1)+c(i+511)-c1
         c1=c(i)                      !Save original value
         c(i)=zz                      !Save the sum
      enddo

C  Iterate to find the best jstart.
      jstart=jstart+NB3
      nz=(jz-jstart)/NB3 -1
      smax=0.
      jstep=256
      jbest=jstart

 10   jstep=jstep/2
      jstart=jbest
      do j=jstart-jstep,jstart+jstep,jstep
         s=0.
         r=0.
         do n=1,nz
            k=(n-1)*NB3 + j
            s=s + ps(c(k))
            r=r + ps(c(k+512)) + ps(c(k+1024))
         enddo
         s=2*s/r                               !Better to use s/r or s-r?
         if(s.gt.smax) then
            smax=s
            jbest=j
         endif
      enddo
      if(jstep.gt.1) go to 10

      jstart=jbest
      if(jstart.gt.NB3) jstart=jstart-NB3

      return
      end
