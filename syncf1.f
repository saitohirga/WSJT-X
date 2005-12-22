      subroutine syncf1(data,jz,jstart,f0,NFreeze,smax,red)

C  Does 16k FFTs of data with stepsize 15360, using only "sync on" intervals.
C  Returns a refined value of f0, the sync-tone frequency.

      parameter (NFFT=16384)
      parameter (NH=NFFT/2)
      parameter (NQ=NFFT/4)
      parameter (NB3=3*512)
      real data(jz)                          !Raw data
      real x(NFFT)
      real red(512)
      real s(NQ)     !Ref spectrum for flattening and birdie-zapping

      complex c(0:NH)
      complex z
      equivalence (x,c)

      ps(z)=real(z)**2 + imag(z)**2          !Power spectrum ASF

C  Accumulate a high-resolution average spectrum
      df=11025.0/NFFT
      jstep=10*NB3
      nz=(jz-jstart)/jstep -1
      call zero(s,NQ)
      do n=1,nz
         call zero(x,NFFT)
         k=(n-1)*jstep
         do i=1,10
            j=(i-1)*NB3 + 1
            call move(data(jstart+k+j),x(j),512)
         enddo
         call xfft(x,NFFT)
         do i=1,NQ
            x(i)=ps(c(i))
         enddo
         call add(s,x,s,NQ)
      enddo

      fac=(1.0/NFFT)**2
      do i=1,NQ                                !Normalize
         s(i)=fac*s(i)
      enddo

C  NB: could also compute a "blue" spectrum, using the sync-off intervals.
      n8=NQ/8
      do i=1,n8
         red(i)=0.
         do k=8*i-7,8*i
            red(i)=red(i)+s(k)
         enddo
         red(i)=10.0*red(i)/(8.0*nz)
      enddo

C  Find improved value for f0
      smax=0.
      ia=(f0-25.)/df
      ib=(f0+25.)/df
      if(NFreeze.eq.1) then
         ia=(f0-5.)/df
         ib=(f0+5.)/df
      endif
      do i=ia,ib
         if(s(i).gt.smax) then
            smax=s(i)
            ipk=i
         endif
      enddo
      f0=ipk*df

C  Remove line at f0 from spectrum -- if it's strong enough.
      ia=(f0-150)/df
      ib=(f0+150)/df
      a1=0.
      a2=0.
      nsum=50
      do i=1,nsum
         a1=a1+s(ia-i)
         a2=a2+s(ib+i)
      enddo
      a1=a1/nsum
      a2=a2/nsum
      smax=2.0*smax/(a1+a2)

      if(smax.gt.3.0) then
         b=(a2-a1)/(ib-ia)
         do i=ia,ib
            s(i)=a1 + (i-ia)*b
         enddo
      endif

C  Make a smoothed version of the spectrum.
      nsum=50
      fac=1./(2*nsum+1)
      call zero(x,nsum)
      call zero(s,50)
      call zero(s(NQ-nsum),nsum)
      sum=0.
      do i=nsum+1,NQ-nsum
         sum=sum+s(i+nsum)-s(i-nsum)
         x(i)=fac*sum
      enddo
      call zero(x(NQ-nsum),nsum+1)

C  To zap birdies, compare s(i) and x(i).  If s(i) is larger by more
C  than some limit, replace x(i) by s(i).  That will put narrow birdies
C  on top of the smoothed spectrum.

      call move(x,s,NQ)                 !Copy smoothed spectrum into s

      return
      end
