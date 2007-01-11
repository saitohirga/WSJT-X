      subroutine flatten(s2,nbins,jz,psa,ref,birdie,variance)

C  Examines the 2-d spectrum s2(nbins,jz) and makes a reference spectrum
C  from the jz/2 spectra below the 50th percentile in total power.  Uses
C  reference spectrum (with birdies removed) to flatten the passband.

      real s2(nbins,jz)               !2d spectrum
      real psa(nbins)                 !Grand average spectrum
      real ref(nbins)                 !Ref spect: smoothed ave of lower half
      real birdie(nbins)              !Spec (with birdies) for plot, in dB
      real variance(nbins)
      real ref2(750)                  !Work array
      real power(300)
      
C  Find power in each time block, then get median
      do j=1,jz
         s=0.
         do i=1,nbins
            s=s+s2(i,j)
         enddo
         power(j)=s
      enddo
      call pctile(power,ref2,jz,50,xmedian)
      if(jz.lt.5) go to 900

C  Get variance in each freq channel, using only those spectra with
C  power below the median.
      do i=1,nbins                        
         s=0.
         nsum=0
         do j=1,jz
            if(power(j).le.xmedian) then
               s=s+s2(i,j)
               nsum=nsum+1
            endif
         enddo
         s=s/nsum
         sq=0.
         do j=1,jz
            if(power(j).le.xmedian) sq=sq + (s2(i,j)/s-1.0)**2
         enddo
         variance(i)=sq/nsum
      enddo

C  Get grand average, and average of spectra with power below median.
      call zero(psa,nbins)
      call zero(ref,nbins)
      nsum=0
      do j=1,jz
         call add(psa,s2(1,j),psa,nbins)
         if(power(j).le.xmedian) then
            call add(ref,s2(1,j),ref,nbins)
            nsum=nsum+1
         endif
      enddo
      do i=1,nbins                          !Normalize the averages
         psa(i)=psa(i)/jz
         ref(i)=ref(i)/nsum
         birdie(i)=ref(i)                   !Copy ref into birdie
      enddo

C  Compute smoothed reference spectrum with narrow lines (birdies) removed
      do i=4,nbins-3
         rmax=-1.e10
         do k=i-3,i+3                  !Get highest point within +/- 3 bins
            if(ref(k).gt.rmax) then
               rmax=ref(k)
               kpk=k
            endif
         enddo
         sum=0.
         nsum=0
         do k=i-3,i+3
            if(abs(k-kpk).gt.1) then
               sum=sum+ref(k)
               nsum=nsum+1
            endif
         enddo
         ref2(i)=sum/nsum
      enddo
      call move(ref2(4),ref(4),nbins-6)     !Copy smoothed ref back into ref
      
      call pctile(ref(4),ref2,nbins-6,50,xmedian)  !Get median in-band level

C  Fix ends of reference spectrum
      do i=1,3
         ref(i)=ref(4)
         ref(nbins+1-i)=ref(nbins-3)
      enddo

      facmax=30.0/xmedian
      do i=1,nbins                          !Flatten the 2d spectrum
         fac=xmedian/ref(i)
         fac=min(fac,facmax)
         do j=1,jz
            s2(i,j)=fac*s2(i,j)
         enddo
         psa(i)=dB(psa(i)) + 25.
         ref(i)=dB(ref(i)) + 25.
         birdie(i)=db(birdie(i)) + 25.
      enddo

900   continue
      return
      end
