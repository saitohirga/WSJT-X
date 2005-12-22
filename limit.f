      subroutine limit(x,jz)

      real x(jz)
      logical noping
      common/limcom/ nslim2

      noping=.false.
      xlim=1.e30
      if(nslim2.eq.1) xlim=3.0
      if(nslim2.ge.2) xlim=1.0
      if(nslim2.ge.3) noping=.true.

      sq=0.
      do i=1,jz
         sq=sq+x(i)*x(i)
      enddo
      rms=sqrt(sq/jz)
      rms0=14.5
      x1=xlim*rms0
      fac=1.0/xlim
      if(fac.lt.1.0) fac=1.0
      if(noping .and. rms.gt.20.0) fac=0.01    !Crude attempt at ping excision

      do i=1,jz
         if(x(i).lt.-x1) x(i)=-x1
         if(x(i).gt.x1) x(i)=x1
         x(i)=fac*x(i)
      enddo

      return
      end
