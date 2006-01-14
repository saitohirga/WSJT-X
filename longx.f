      subroutine longx(dat,npts0,ps,DFTolerance,noffset,
     +    msg,msglen,bauderr,MouseButton)

C  Look for 441-baud modulation, synchronize to it, and decode message.
C  Longest allowed data analysis is 1 second.

      parameter (NMAX=11025)
      parameter (NDMAX=NMAX/25)
      real dat(npts0)
      real ps(128),psmo(20)
      integer DFTolerance
      real y1(NMAX)
      real y2(NMAX)
      real y3(NMAX)
      real y4(NMAX)
      real wgt(-2:2)
      integer dit(NDMAX)
      integer n4(0:2)
      character msg*40
      character c*48
      common/acom/a1,a2,a3,a4
      data c/' 123456789.,?/# $ABCD FGHIJKLMNOPQRSTUVWXY 0EZ  '/
      data wgt/1.0,4.0,6.0,4.0,1.0/

      NSPD=25                                !Change if FSK110 is implemented
      LTone=2
      NBaud=11025/NSPD
      npts=min(NMAX,npts0)
      df=11025.0/256.0
      smax=0.

C  Find the frequency offset of this ping.
C  NB: this might be improved by including a bandpass correction to ps.

      ia=nint((LTone*NBaud-DFTolerance)/df)
      ib=nint((LTone*NBaud+DFTolerance)/df)

      do i=ia,ib                            !Search for correct DF
         sum=0.
         do j=1,4                           !Sum over the 4 tones
            m=nint((i*df+(j-1)*NBaud)/df)
            do k=-2,2                       !Weighted averages over 5 bins
               sum=sum+wgt(k)*ps(m+k)
            enddo
         enddo
         k=i-ia+1
         psmo(k)=sum
         kpk=0
         if(sum.gt.smax) then
            smax=sum
            noffset=nint(i*df-LTone*NBaud)
            kpk=k
         endif
      enddo


      if(kpk.gt.1 .and. kpk.lt.20) then
         call peakup(psmo(kpk-1),psmo(kpk),psmo(kpk+1),dx)
         noffset=nint(noffset+dx*df)
      endif

C  Do square-law detection in each of four filters.
      f1=LTone*NBaud+noffset
      f2=(LTone+1)*NBaud+noffset
      f3=(LTone+2)*NBaud+noffset
      f4=(LTone+3)*NBaud+noffset
      call detect(dat,npts,f1,y1)
      call detect(dat,npts,f2,y2)
      call detect(dat,npts,f3,y3)
      call detect(dat,npts,f4,y4)

C  Bandpass correction:
      npts=npts-(NSPD-1)
      do i=1,npts
         y1(i)=y1(i)*a1
         y2(i)=y2(i)*a2
         y3(i)=y3(i)*a3
         y4(i)=y4(i)*a4
      enddo

      call sync(y1,y2,y3,y4,npts,jpk,baud,bauderr)

C  Decimate y arrays by NSPD
      ndits=npts/NSPD - 1
      do i=1,ndits
         y1(i)=y1(jpk+(i-1)*NSPD)
         y2(i)=y2(jpk+(i-1)*NSPD)
         y3(i)=y3(jpk+(i-1)*NSPD)
         y4(i)=y4(jpk+(i-1)*NSPD)
      enddo

C  Now find the mod3 phase that has no tone 3's
      n4(0)=0
      n4(1)=0
      n4(2)=0
      do i=1,ndits
         ymax=max(y1(i),y2(i),y3(i),y4(i))
         if(y1(i).eq.ymax) dit(i)=0
         if(y2(i).eq.ymax) dit(i)=1
         if(y3(i).eq.ymax) dit(i)=2
         if(y4(i).eq.ymax) then
            dit(i)=3
            k=mod(i,3)
            n4(k)=n4(k)+1
         endif
      enddo

      n4min=min(n4(0),n4(1),n4(2))
      if(n4min.eq.n4(0)) jsync=3
      if(n4min.eq.n4(1)) jsync=1
      if(n4min.eq.n4(2)) jsync=2
C  Might want to notify if n4min>0 or if one of the others is equal
C  to n4min.  In both cases, could then decode 2 or 3 times, using
C  other starting phases.

C  Finally, decode the message.
      msg='                                        '
      msglen=ndits/3
      msglen=min(msglen,40)
      do i=1,msglen
         j=(i-1)*3+jsync
         nc=16*dit(j) + 4*dit(j+1) +dit(j+2)
         msg(i:i)=' '
         if(nc.le.47) msg(i:i)=c(nc+1:nc+1)
      enddo

      return
      end
