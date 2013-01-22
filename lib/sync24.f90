subroutine sync24(dat,jz,DFTolerance,NFreeze,MouseDF,mode,mode4,    &
     dtx,dfx,snrx,snrsync,ccfblue,ccfred1,flip,width)

! Synchronizes JT4 data, finding the best-fit DT and DF.  

  parameter (NFFTMAX=2520)         !Max length of FFTs
  parameter (NHMAX=NFFTMAX/2)      !Max length of power spectra
  parameter (NSMAX=525)            !Max number of half-symbol steps
  integer DFTolerance              !Range of DF search
  real dat(jz)
  real psavg(NHMAX)                !Average spectrum of whole record
  real s2(NHMAX,NSMAX)             !2d spectrum, stepped by half-symbols
  real ccfblue(-5:540)             !CCF with pseudorandom sequence
  real ccfred(-450:450)            !Peak of ccfblue, as function of freq
  real ccfred1(-224:224)           !Peak of ccfblue, as function of freq
  real tmp(1260)
  save

! Do FFTs of twice symbol length, stepped by half symbols.  Note that 
! we have already downsampled the data by factor of 2.

  nsym=207
  nfft=2520
  nh=nfft/2
  nq=nfft/4
  nsteps=jz/nq - 1
  df=0.5*11025.0/nfft
  psavg(1:nh)=0.

  do j=1,nsteps                     !Compute spectrum for each step, get average
     k=(j-1)*nq + 1
     call ps24(dat(k),nfft,s2(1,j))
     psavg(1:nh)=psavg(1:nh) + s2(1:nh,j)
  enddo

  call flat1(psavg,s2,nh,nsteps,NHMAX,NSMAX)        !Flatten spectra

! Set freq and lag ranges
  famin=200.
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
  if(mode.eq.7) then
     ia=ia - 3*mode4
     ib=ib - 3*mode4
  endif
  i0=nint(1270.46/df)
  lag1=-5
  lag2=59
  syncbest=-1.e30
  syncbest2=-1.e30
  ccfred=0.

  do i=ia,ib                                !Find best frequency channel for CCF

     call xcor24(s2,i,nsteps,nsym,lag1,lag2,mode4,ccfblue,ccf0,lagpk0,flip)
     j=i-i0
     if(mode.eq.7) j=j + 3*mode4
     if(j.ge.-372 .and. j.le.372) ccfred(j)=ccf0

! Find rms of the CCF, without main peak
     call slope(ccfblue(lag1),lag2-lag1+1,lagpk0-lag1+1.0)
     sync=abs(ccfblue(lagpk0))
     ppmax=psavg(i)-1.0

! Find best sync value
     if(sync.gt.syncbest2) then
        ipk2=i
        lagpk2=lagpk0
        syncbest2=sync
     endif

! We are most interested if snrx will be more than -30 dB.
     if(ppmax.gt.0.2938) then            !Corresponds to snrx.gt.-30.0
        if(sync.gt.syncbest) then
           ipk=i
           lagpk=lagpk0
           syncbest=sync
        endif
     endif
  enddo

! If we found nothing with snrx > -30 dB, take the best sync that *was* found.
  if(syncbest.lt.-10.) then
     ipk=ipk2
     lagpk=lagpk2
     syncbest=syncbest2
  endif

  dfx=(ipk-i0)*df
  if(mode.eq.7) dfx=dfx + 3*mode4*df

! Peak up in time, at best whole-channel frequency
  call xcor24(s2,ipk,nsteps,nsym,lag1,lag2,mode4,ccfblue,ccfmax,lagpk,flip)
  xlag=lagpk
  if(lagpk.gt.lag1 .and. lagpk.lt.lag2) then
     call peakup(ccfblue(lagpk-1),ccfmax,ccfblue(lagpk+1),dx2)
     xlag=lagpk+dx2
  endif

! Find rms of the CCF, without the main peak
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
  snrsync=abs(ccfblue(lagpk))/rms - 1.1                       !Empirical

  dt=2.0/11025.0
  istart=xlag*nq
  dtx=istart*dt
  snrx=-99.0
  ppmax=psavg(ipk)-1.0

  if(ppmax.gt.0.0001) then
     snrx=db(ppmax*df/2500.0) + 7.5        !Empirical
     if(mode.eq.7) snrx=snrx + 3.0         !Empirical
  endif
  if(snrx.lt.-33.0) snrx=-33.0

! Compute width of sync tone to outermost -3 dB points
  i1=max(-450,ia-i0)
  i2=min(450,ib-i0)
  call pctile(ccfred(i1),i2-i1+1,45,base)

  jpk=ipk-i0
  if(abs(jpk).gt.450) then
     print*,'sync24 a:',jpk,ipk,i0
     snrsync=0.
     go to 999
  else
     stest=base + 0.5*(ccfred(jpk)-base) ! -3 dB
  endif
  do i=-10,0
     if(jpk+i.ge.-371) then 
        if(ccfred(jpk+i).gt.stest) go to 30
     endif
  enddo
  i=0
30 continue
  if(abs(jpk+i-1).gt.450 .or. abs(jpk+i).gt.450) then
     print*,'sync24 b:',jpk,i
  else
     x1=i-0.5
  endif

  do i=10,0,-1
     if(jpk+i.le.371) then
        if(ccfred(jpk+i).gt.stest) go to 32
     endif
  enddo
  i=0
32 x2=i+0.5
  width=x2-x1
  if(width.gt.1.2) width=sqrt(width**2 - 1.44)
  width=df*width
  width=max(0.0,min(99.0,width))

  do i=-224,224
     ccfred1(i)=ccfred(i)
  enddo

999 return
end subroutine sync24

