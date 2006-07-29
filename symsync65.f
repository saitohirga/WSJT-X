      subroutine symsync65(c5,n5,k0,s,flip,pr,kmax,kpk,ccf,smax)

      complex c5(n5)
      real s(n5),pr(126),ccf(-128:128)
      complex z

      z=0.
      do i=1,32
         z=z + c5(i)
      enddo
      s(1)=real(z)*real(z) + aimag(z)*aimag(z)
      smax=s(1)
      do i=33,n5
         z=z + c5(i) - c5(i-32)
         s(i-31)=real(z)*real(z) + aimag(z)*aimag(z)
         smax=max(s(i-31),smax)
      enddo
      iz=n5-31

      smax=0.
      do k=-kmax,kmax
         sum=0.
         do i=1,126
            j=32*(i-1)+k+k0
            if(j.ge.1 .and. j.le.iz) sum=sum + flip*pr(i)*s(j)
         enddo
         ccf(k)=sum
         if(sum.gt.smax) then
            smax=sum
            kpk=k
         endif
      enddo

      return
      end
