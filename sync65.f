      subroutine sync65(dat,jz,DFTolerance,NFreeze,MouseDF,
     +  mode65,dtx,dfx,snrx,snrsync,ccfblue,ccfred1,flip,width)

C  Synchronizes JT65 data, finding the best-fit DT and DF.  
C  NB: at this stage, submodes ABC are processed in the same way.

      parameter (NP2=60*11025)         !Size of data array
      parameter (NFFTMAX=2048)         !Max length of FFTs
      parameter (NHMAX=NFFTMAX/2)      !Max length of power spectra
      parameter (NSMAX=320)            !Max number of half-symbol steps
      integer DFTolerance              !Range of DF search
      real dat(jz)
      real psavg(NHMAX)                !Average spectrum of whole record
      real s2(NHMAX,NSMAX)             !2d spectrum, stepped by half-symbols
      real ccfblue(-5:540)             !CCF with pseudorandom sequence

C  The value 450 is empirical:
      real ccfred(-450:450)            !Peak of ccfblue, as function of freq
      real ccfred1(-224:224)           !Peak of ccfblue, as function of freq
      real tmp(450)
      save

C  Do FFTs of symbol length, stepped by half symbols.  Note that we have
C  already downsampled the data by factor of 2.
      nsym=126
      nfft=2048
      nsteps=2*jz/nfft - 1
      nh=nfft/2

      df=0.5*11025.0/nfft
C  Compute power spectrum for each step and get average
      call zero(psavg,nh)
      do j=1,nsteps
         k=(j-1)*nh + 1
         call limit(dat(k),nfft)
         call ps(dat(k),nfft,s2(1,j))
         if(mode65.eq.4) call smooth(s2(1,j),nh)
         call add(psavg,s2(1,j),psavg,nh)
      enddo

      call flat1(psavg,s2,nh,nsteps,NHMAX,NSMAX)        !Flatten the spectra

C  Find the best frequency channel for CCF
!      famin= 670.46
!      fbmax=1870.46
      famin=3.
      fbmax=2700.

      fa=famin
      fb=fbmax
      if(NFreeze.eq.1) then
         fa=max(famin,1270.46+MouseDF-DFTolerance)
         fb=min(fbmax,1270.46+MouseDF+DFTolerance)
      else
         fa=max(famin,1270.46+MouseDF-600)
         fb=min(fbmax,1270.46+MouseDF+600)
      endif
      ia=fa/df
      ib=fb/df
      i0=nint(1270.46/df)
      lag1=-5
      lag2=59
      syncbest=-1.e30
      syncbest2=-1.e30

      call zero(ccfred,745)
      do i=ia,ib
         call xcor(s2,i,nsteps,nsym,lag1,lag2,
     +        ccfblue,ccf0,lagpk0,flip,0.0)
         j=i-i0
         if(j.ge.-372 .and. j.le.372) ccfred(j)=ccf0

C  Find rms of the CCF, without the main peak
         call slope(ccfblue(lag1),lag2-lag1+1,lagpk0-lag1+1.0)
         sync=abs(ccfblue(lagpk0))
         ppmax=psavg(i)-1.0

C  Find the best sync value
         if(sync.gt.syncbest2) then
            ipk2=i
            lagpk2=lagpk0
            syncbest2=sync
         endif

C  We are most interested if snrx will be more than -30 dB.
         if(ppmax.gt.0.2938) then            !Corresponds to snrx.gt.-30.0
            if(sync.gt.syncbest) then
               ipk=i
               lagpk=lagpk0
               syncbest=sync
            endif
         endif
      enddo

C  If we found nothing with snrx > -30 dB, take the best sync that *was* found.
      if(syncbest.lt.-10.) then
         ipk=ipk2
         lagpk=lagpk2
         syncbest=syncbest2
      endif

C  Peak up in frequency to fraction of channel
      base=0.25*(psavg(ipk-3)+psavg(ipk-2)+psavg(ipk+2)+psavg(ipk+3))
!      call peakup(psavg(ipk-1),psavg(ipk),psavg(ipk+1),dx)
!      if(dx.lt.-1.0) dx=-1.0
!      if(dx.gt.1.0) dx=1.0
      dx=0.
      dfx=(ipk+dx-i0)*df

C  Peak up in time, at best whole-channel frequency
      call xcor(s2,ipk,nsteps,nsym,lag1,lag2,
     +  ccfblue,ccfmax,lagpk,flip,0.0)
      xlag=lagpk
      if(lagpk.gt.lag1 .and. lagpk.lt.lag2) then
         call peakup(ccfblue(lagpk-1),ccfmax,ccfblue(lagpk+1),dx2)
         xlag=lagpk+dx2
      endif

C  Find rms of the CCF, without the main peak
      call slope(ccfblue(lag1),lag2-lag1+1,xlag-lag1+1.0)
      sq=0.
      nsq=0
      do lag=lag1,lag2
         if(abs(lag-xlag).gt.2.0) then
            sq=sq+ccfblue(lag)**2
            nsq=nsq+1
         endif
      enddo
      rms=sqrt(sq/nsq)
      snrsync=abs(ccfblue(lagpk))/rms - 1.1    !Empirical

      dt=2.0/11025.0
      istart=xlag*nh
      dtx=istart*dt
      snrx=-99.0
!      ppmax=psavg(ipk)/base-1.0
      ppmax=psavg(ipk)-1.0
C  Plus 3 dB because sync tone is on half the time.  (Don't understand 
C  why an additional +2 dB is needed ...)
      if(ppmax.gt.0.0001) snrx=db(ppmax*df/2500.0) + 5.0    !###
      if(mode65.eq.4) snrx=snrx + 2.0
      if(snrx.lt.-33.0) snrx=-33.0

C  Compute width of sync tone to outermost -3 dB points
      call pctile(ccfred(ia-i0),tmp,ib-ia+1,45,base)

      jpk=ipk-i0
      stest=base + 0.5*(ccfred(jpk)-base)                ! -3 dB
      do i=-10,0
         if(jpk+i.ge.-371) then 
            if(ccfred(jpk+i).gt.stest) go to 30
         endif
      enddo
      i=0
 30   x1=i-1+(stest-ccfred(jpk+i-1))/(ccfred(jpk+i)-ccfred(jpk+i-1))

      do i=10,0,-1
         if(jpk+i.le.371) then
            if(ccfred(jpk+i).gt.stest) go to 32
         endif
      enddo
      i=0
 32   x2=i+1-(stest-ccfred(jpk+i+1))/(ccfred(jpk+i)-ccfred(jpk+i+1))
      width=x2-x1
      if(width.gt.1.2) width=sqrt(width**2 - 1.44)
      width=df*width
      width=max(0.0,min(99.0,width))

      do i=-224,224
         ccfred1(i)=ccfred(i)
      enddo

      return
      end

