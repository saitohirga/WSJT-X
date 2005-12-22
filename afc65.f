      subroutine afc65(s2,ipk,lagpk,flip,ftrack)

      real s2(1024,320)
      real s(-10:10)
      real x(63),y(63),z(63)
      real ftrack(126)
      include 'prcom.h'
      data s/21*0.0/

      k=0
      u=1.0
      u1=0.2
      fac=sqrt(1.0/u1)
      do j=1,126
         if(pr(j)*flip .lt. 0.0) go to 10
         k=k+1
         m=2*j-1+lagpk
         if(m.lt.1 .or. m.gt.320) go to 10
         smax=0.
         do i=-10,10
            s(i)=(1.0-u)*s(i) + u*s2(ipk+i,m)
            if(s(i).gt.smax) then
               smax=s(i)
               ipk2=i
            endif
         enddo
         u=u1
         dfx=0.0
         sig=100.0*fac*smax
         if(ipk2.gt.-10 .and. ipk2.lt.10 .and. (sig.gt.2.0)) 
     +      call peakup(s(ipk2-1),s(ipk2),s(ipk2+1),dfx)
         dfx=ipk2+dfx
         x(k)=j
         y(k)=dfx
         z(k)=sig
         if(z(k).lt.1.5 .or. abs(y(k)).gt.5.5) then
            y(k)=0.
            z(k)=0.
         endif
 10   enddo

      zlim=5.0
      yfit=0.
      k=0
      do j=1,126
         if(pr(j)*flip .lt. 0.0) go to 30
         k=k+1
         sumy=0.
         sumz=0.
         if(k.ge.1) then
            sumz=z(k)
            sumy=sumy+z(k)*y(k)
         endif
         do n=1,30
            m=k-n
            if(m.ge.1)  then
               sumz=sumz+z(m)
               sumy=sumy+z(m)*y(m)
            endif
            m=k+n
            if(m.le.63) then
               sumz=sumz+z(m)
               sumy=sumy+z(m)*y(m)
            endif
            if(sumz.ge.zlim) go to 20
         enddo
         n=30
 20      yfit=0.
         if(sumz.gt.0.0) yfit=sumy/sumz

 30      ftrack(j)=yfit*2.691650
      enddo
      if(ftrack(1).eq.99.0) ftrack(1)=ftrack(2)

      return
      end

