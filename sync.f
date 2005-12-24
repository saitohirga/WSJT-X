      subroutine sync(y1,y2,y3,y4,npts,jpk,baud,bauderr)

C  Input data are in the y# arrays: detected sigs in four tone-channels,
C  before decimation by NSPD.

      parameter (NSPD=25)
      real y1(npts)
      real y2(npts)
      real y3(npts)
      real y4(npts)
      real zf(NSPD)
      complex csum
      integer nsum(NSPD)
      real z(65538)                            !Ready for FSK110
      complex cz(0:32768)
      equivalence (z,cz)
      data twopi/6.283185307/

      do i=1,NSPD
         zf(i)=0.0
         nsum(i)=0
      enddo

      do i=1,npts
         a1=max(y1(i),y2(i),y3(i),y4(i))       !Find the largest one

         if(a1.eq.y1(i)) then                  !Now find 2nd largest
            a2=max(y2(i),y3(i),y4(i))
         else if(a1.eq.y2(i)) then
            a2=max(y1(i),y3(i),y4(i))
         else if(a1.eq.y3(i)) then
            a2=max(y1(i),y2(i),y4(i))
         else 
            a2=max(y1(i),y2(i),y3(i))
         endif

         z(i)=1.e-6*(a1-a2)                     !Subtract 2nd from 1st
         j=mod(i-1,NSPD)+1
         zf(j)=zf(j)+z(i)
         nsum(j)=nsum(j)+1
      enddo

      n=log(float(npts))/log(2.0)
      nfft=2**(n+1)
      call zero(z(npts+1),nfft-npts)
      call xfft(z,nfft)

C  Now find the apparent baud rate.
      df=11025.0/nfft
      zmax=0.
      ia=391.0/df                                !Was 341/df
      ib=491.0/df                                !Was 541/df
      do i=ia,ib
         z(i)=real(cz(i))**2 + imag(cz(i))**2
         if(z(i).gt.zmax) then
            zmax=z(i)
            baud=df*i
         endif
      enddo

C  Find phase of signal at 441 Hz.
      csum=0.
      do j=1,NSPD
         pha=j*twopi/NSPD
         csum=csum+zf(j)*cmplx(cos(pha),-sin(pha))
      enddo
      pha=-atan2(imag(csum),real(csum))
      jpk=nint(NSPD*pha/twopi)
      if(jpk.lt.1) jpk=jpk+NSPD

C The following is nearly equivalent to the above.  I don't know which
C (if either) is better.
c      zfmax=-1.e30
c      do j=1,NSPD
c         if(zf(j).gt.zfmax) then
c            zfmax=zf(j)
c            jpk2=j
c         endif
c      enddo

      bauderr=(baud-11025.0/NSPD)/df   !Baud rate error, in bins
      return
      end
