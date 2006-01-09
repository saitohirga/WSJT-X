      subroutine syncf0(data,jz,NFreeze,NTol,jstart,f0,smax)

C  Does 512-pt FFTs of data with 256-pt step size.
C  Finds sync tone and determines aproximate values for jstart and f0.

      real data(jz)               !Raw data
      real s2(128,6)              !Average spectra at half-symbol spacings
      real x(512)
      complex cx(0:511)
      complex z
      equivalence (x,cx)

      ps(z)=real(z)**2 + imag(z)**2          !Power spectrum function

      call zero(s2,6*128)                    !Clear average
      df=11025./512.

      ia=(f0-400)/df
      ib=(f0+400)/df + 0.999
      if(NFreeze.eq.1) then
         ia=(f0-NTol)/df
         ib=(f0+Ntol)/df + 0.999
      endif

C  Most of the time in this routine is in this loop.

      nblk=jz/256 - 6
      do n=1,nblk                            !Accumulate avg spectrum for
         j=256*(n-1)+1                       !512-pt blocks, stepping by 256
         call move(data(j),x,512)
         call xfft(x,512)
         do i=ia,ib
            x(i)=ps(cx(i))
         enddo
         k=mod(n-1,6)+1
         call add(s2(ia,k),x(ia),s2(ia,k),ib-ia+1)  !Average at each step
      enddo

C  Look for best spectral peak, using the "sync off" phases as reference.
      smax=0.
      do i=ia,ib
         do k=1,6
            k1=mod(k+1,6)+1
            k2=mod(k+3,6)+1
            r=0.5*(s2(i,k1)+s2(i,k2))
            s=s2(i,k)/r
            if(s.gt.smax) then
               smax=s
               jstart=(k-1)*256 + 1      !Best starting place for sync
               f0=i*df                   !Best sync frequency
            endif
         enddo
      enddo

      return
      end
