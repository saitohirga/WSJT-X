subroutine sync4(dat,jz,ntol,NFreeze,nfqso,mode,mode4,minwidth,    &
     dtx,dfx,snrx,snrsync,ccfblue,ccfred1,flip,width)

! Synchronizes JT4 data, finding the best-fit DT and DF.  

  parameter (NFFTMAX=2520)         !Max length of FFTs
  parameter (NHMAX=NFFTMAX/2)      !Max length of power spectra
  parameter (NSMAX=525)            !Max number of half-symbol steps
  integer ntol                     !Range of DF search
  real dat(jz)
  real psavg(NHMAX)                !Average spectrum of whole record
  real s2(NHMAX,NSMAX)             !2d spectrum, stepped by half-symbols
  real ccfblue(-5:540)             !CCF with pseudorandom sequence
  real ccfred(-450:450)            !Peak of ccfblue, as function of freq
  real red(-450:450)               !Peak of ccfblue, as function of freq
  real ccfred1(-224:224)           !Peak of ccfblue, as function of freq
  real tmp(1260)
  integer ipk1(1)
  integer nch(7)
  logical savered
  equivalence (ipk1,ipk1a)
  data nch/1,2,4,9,18,36,72/
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
  if(mode.eq.-999) width=0.                        !Silence compiler warning

  do j=1,nsteps                     !Compute spectrum for each step, get average
     k=(j-1)*nq + 1
     call ps4(dat(k),nfft,s2(1,j))
     psavg(1:nh)=psavg(1:nh) + s2(1:nh,j)
  enddo

  nsmo=min(10*mode4,150)
  call flat1b(psavg,nsmo,s2,nh,nsteps,NHMAX,NSMAX)        !Flatten spectra

  if(mode4.ge.9) then
     call smo(psavg,nh,tmp,mode4/4)
     psavg=psavg/(mode4/4.0)
     do j=1,nsteps
        call smo(s2(1,j),nh,tmp,mode4/4)
     enddo
     s2=s2/(mode4/4.0)
  endif

! Set freq and lag ranges
  famin=200.0 + 3*mode4*df
  fbmax=2700.0 - 3*mode4*df
  fa=famin
  fb=fbmax
  mousedf=nint(nfqso + 1.5*4.375*mode4 - 1270.46)
  if(NFreeze.eq.1) then
     fa=max(famin,1270.46+MouseDF-ntol)
     fb=min(fbmax,1270.46+MouseDF+ntol)
  else
     fa=max(famin,1270.46+MouseDF-600)
     fb=min(fbmax,1270.46+MouseDF+600)
  endif
  ia=fa/df - 3*mode4                   !Index of lowest tone, bottom of range
  ib=fb/df - 3*mode4                   !Index of lowest tone, top of range
  i0=nint(1270.46/df)
  irange=450
  if(ia-i0.lt.-irange) ia=i0-irange
  if(ib-i0.gt.irange)  ib=i0+irange
  lag1=-5
  lag2=59
  syncbest=-1.e30
  ccfred=0.
  jmax=-1000
  jmin=1000
!  rewind 83

  do ich=minwidth,7                       !Find best width
     savered=.false.
     do i=ia,ib                           !Find best frequency channel for CCF
        call xcor4(s2,i,nsteps,nsym,lag1,lag2,ich,mode4,ccfblue,ccf0,   &
             lagpk0,flip)
        j=i-i0 + 3*mode4
        if(j.ge.-372 .and. j.le.372) then
           ccfred(j)=ccf0
!           write(83,4001) i*df,ccf0
!4001       format(f10.1,e12.3)
           jmax=max(j,jmax)
           jmin=min(j,jmin)
        endif

! Normalize ccfblue so that baseline rms = 1.0
        call slope(ccfblue(lag1),lag2-lag1+1,lagpk0-lag1+1.0)
        sync=abs(ccfblue(lagpk0))

! Find best sync value
        if(sync.gt.syncbest) then
           ipk=i
           lagpk=lagpk0
           ichpk=ich
           syncbest=sync
           savered=.true.
        endif
     enddo
     if(savered) red=ccfred
  enddo

  ccfred=red
!  width=df*nch(ichpk)
  dfx=(ipk-i0 + 3*mode4)*df

! Peak up in time, at best whole-channel frequency
  call xcor4(s2,ipk,nsteps,nsym,lag1,lag2,ichpk,mode4,ccfblue,ccfmax,   &
       lagpk,flip)
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
  snrsync=max(0.0,db(abs(ccfblue(lagpk)/rms - 1.0)) - 4.5)
  snrx=-26.
  if(mode4.eq.2)  snrx=-25.
  if(mode4.eq.4)  snrx=-24.
  if(mode4.eq.9)  snrx=-23.
  if(mode4.eq.18) snrx=-22.
  if(mode4.eq.36) snrx=-21.
  if(mode4.eq.72) snrx=-20.
  snrx=snrx + snrsync

  dt=2.0/11025.0
  istart=xlag*nq
  dtx=istart*dt
  ccfred1=0.
  jmin=max(jmin,-224)
  jmax=min(jmax,224)
  do i=jmin,jmax
     ccfred1(i)=ccfred(i)
  enddo

  ipk1=maxloc(ccfred1) - 225
  ns=0
  s=0.
  iw=min(mode4,(ib-ia)/4)
  do i=jmin,jmax
     if(abs(i-ipk1a).gt.iw) then
        s=s+ccfred1(i)
        ns=ns+1
     endif
  enddo
  base=s/ns
  ccfred1=ccfred1-base
  ccf10=0.5*maxval(ccfred1)
  do i=ipk1a,jmin,-1
     if(ccfred1(i).le.ccf10) exit
  enddo
  i1=i
  do i=ipk1a,jmax
     if(ccfred1(i).le.ccf10) exit
  enddo
  width=(i-i1)*df

!  rewind 80
!  rewind 81
!  rewind 82

!  do i=1,NHMAX
!     write(80,3004) i*df,psavg(i),sum(s2(i,1:nsteps))
!3004 format(f10.1,2e12.3)
!  enddo

!  do i=jmin,jmax
!     write(81,3001) i,ccfred1(i),width
!3001 format(i5,2f10.3)
!  enddo
!  do i=lag1,lag2
!     write(82,3002) i,ccfblue(i)
!3002 format(i5,f10.3)
!  enddo
!  flush(80)
!  flush(81)
!  flush(82)
!  flush(83)

  return
end subroutine sync4

