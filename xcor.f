      subroutine xcor(s2,ipk,nsteps,nsym,lag1,lag2,
     +  ccf,ccf0,lagpk,flip,fdot)

C  Computes ccf of a row of s2 and the pseudo-random array pr.  Returns
C  peak of the CCF and the lag at which peak occurs.  For JT65, the 
C  CCF peak may be either positive or negative, with negative implying
C  the "OOO" message.

      parameter (NHMAX=1024)           !Max length of power spectra
      parameter (NSMAX=320)            !Max number of half-symbol steps
      real s2(NHMAX,NSMAX)             !2d spectrum, stepped by half-symbols
      real a(NSMAX),a2(NSMAX)
      real ccf(-5:540)
      include 'prcom.h'
      common/clipcom/ nclip
      data lagmin/0/                              !Silence g77 warning
      save

      df=11025.0/4096.
      dtstep=0.5/df
      fac=dtstep/(60.0*df)

      do j=1,nsteps
         ii=nint((j-nsteps/2)*fdot*fac)+ipk
         a(j)=s2(ii,j)
      enddo

C  If requested, clip the spectrum that will be cross correlated.
      nclip=0                               !Turn it off
      if(nclip.gt.0) then
         call pctile(a,a2,nsteps,50,base)
         alow=a2(nint(nsteps*0.16))
         ahigh=a2(nint(nsteps*0.84))
         rms=min(base-alow,ahigh-base)
         clip=4.0-nclip
         atop=base+clip*rms
         abot=base-clip*rms
         do i=1,nsteps
            if(nclip.lt.4) then
               a(i)=min(a(i),atop)
               a(i)=max(a(i),abot)
            else
               if(a(i).ge.base) then
                  a(i)=1.0
               else
                  a(i)=-1.0
               endif
            endif
         enddo 
      endif

      ccfmax=0.
      ccfmin=0.
      do lag=lag1,lag2
         x=0.
         do i=1,nsym
            j=2*i-1+lag
            if(j.ge.1 .and. j.le.nsteps) x=x+a(j)*pr(i)
         enddo
         ccf(lag)=2*x                        !The 2 is for plotting scale
         if(ccf(lag).gt.ccfmax) then
            ccfmax=ccf(lag)
            lagpk=lag
         endif

         if(ccf(lag).lt.ccfmin) then
            ccfmin=ccf(lag)
            lagmin=lag
         endif
      enddo

      ccf0=ccfmax
      flip=1.0
      if(-ccfmin.gt.ccfmax) then
         do lag=lag1,lag2
            ccf(lag)=-ccf(lag)
         enddo
         lagpk=lagmin
         ccf0=-ccfmin
         flip=-1.0
      endif

      return
      end
