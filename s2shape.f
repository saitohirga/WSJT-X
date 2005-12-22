      subroutine s2shape(s2,nchan,nz,tbest)

C  Prepare s2(nchan,nz) for plotting as waterfall.

      real s2(nchan,nz)
      common/fcom/s(3100),indx(3100)

C  Find average of active spectral region, over the whole file.
      sum=0.
      do i=1,44
         do j=1,nz/4
            k=indx(j)
            sum=sum+s2(i+8,k)
         enddo
      enddo

      ave=sum/(44*nz)

C  Subtract the average and normalize.
      do i=1,64
         do j=1,nz
            s2(i,j)=s2(i,j)/ave - 1.0
         enddo
      enddo

      nzz=nz
      nxmax=500                         !Was 494, then 385
      if(nz.lt.nxmax) go to 900
!      fac=float(nz)/nxmax
!      nadd=fac + 0.999999
!      nzz=nxmax
      nadd=3
      nzz=nz/3
      do i=1,64
         do k=1,nzz
            sum=0.
!            j=(k-1)*fac
            j=(k-1)*nadd
            do n=1,nadd
               sum=sum+s2(i,j+n)
            enddo
            s2(i,k)=sum/nadd
         enddo
      enddo

 900  s2(1,1)=nzz
      s2(2,1)=tbest

      return
      end
