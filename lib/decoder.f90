subroutine decoder(ss,c0,nstandalone)

! Decoder for JT9.

  parameter (NMAX=1800*12000)        !Total sample intervals per 30 minutes
  parameter (NDMAX=1800*1500)        !Sample intervals at 1500 Hz rate
  parameter (NSMAX=22000)            !Max length of saved spectra
  real ss(184,NSMAX)
  character*22 msg
  character*80 fmt
  character*20 datetime
  real*4 ccfred(NSMAX)
  logical ccfok(NSMAX)
  logical done(NSMAX)
  integer*1 i1SoftSymbols(207)
  complex c0(NDMAX)
  common/npar/nutc,ndiskdat,ntrperiod,nfqso,newdat,npts8,nfa,nfb,ntol,  &
       kin,nzhsym,nsave,nagain,ndepth,nrxlog,nfsample,datetime
  common/tracer/limtrace,lu
  save

  call system_clock(iclock0,iclock_rate,iclock_max)           !###
  nfreqs0=0
  nfreqs1=0
  ndecodes0=0
  ndecodes1=0

  call timer('decoder ',0)

  open(13,file='decoded.txt',status='unknown')
  ntrMinutes=ntrperiod/60
  newdat=1
  nsynced=0
  ndecoded=0
  nsps=0

  if(ntrMinutes.eq.1) then
     nsps=6912
     df3=1500.0/2048.0
     fmt='(i4.4,i4,i5,f6.1,f8.0,i4,3x,a22)'
  else if(ntrMinutes.eq.2) then
     nsps=15360
     df3=1500.0/2048.0
     fmt='(i4.4,i4,i5,f6.1,f8.0,i4,3x,a22)'
  else if(ntrMinutes.eq.5) then
     nsps=40960
     df3=1500.0/6144.0
     fmt='(i4.4,i4,i5,f6.1,f8.1,i4,3x,a22)'
 else if(ntrMinutes.eq.10) then
     nsps=82944
     df3=1500.0/12288.0
     fmt='(i4.4,i4,i5,f6.1,f8.2,i4,3x,a22)'
  else if(ntrMinutes.eq.30) then
     nsps=252000
     df3=1500.0/32768.0
     fmt='(i4.4,i4,i5,f6.1,f8.2,i4,3x,a22)'
  endif
  if(nsps.eq.0) stop 'Error: bad TRperiod'    !Better: return an error code###

  tstep=0.5*nsps/12000.0                      !Half-symbol step (seconds)
!  idf=ntol/df3 + 0.999
  done=.false.

  do nqd=1,0,-1
     limit=5000
     ccflim=4.0
     if(ndepth.ge.2) then
        limit=50000
        ccflim=3.0
     endif
     if(ndepth.ge.3 .or. nqd.eq.1) then
        limit=200000
        ccflim=2.5
     endif

     if(nqd.eq.1) then
        nfa1=nfqso-ntol
        nfb1=nfqso+ntol
     else
        nfa1=nfa
        nfb1=nfb
     endif
     ia=max(1,nint((nfa1-1000)/df3))
     ib=min(NSMAX,nint((nfb1-1000)/df3))
     lag1=-(2.5/tstep + 0.9999)
     lag2=5.0/tstep + 0.9999
     call timer('sync9   ',0)
! Compute ccfred()
     call sync9(ss,nzhsym,lag1,lag2,ia,ib,ccfred,ipk)
     call timer('sync9   ',1)

     ccfok=.false.

     if(nqd.eq.1) then
        ccfok(ipk)=.true.
        do i=ia,ib
           ccfok(i)=ccfred(i).gt.ccflim
        enddo
        ia1=ia
        ib1=ib
     else
        do i=ia,ib
           ccfok(i)=ccfred(i).gt.ccflim
        enddo
        ccfok(ia1:ib1)=.false.
     endif

     nRxLog=0
     fgood=0.
     nsps8=nsps/8
     df8=1500.0/nsps8
     dblim=db(864.0/nsps8) - 26.2

     do i=ia,ib
        f=(i-1)*df3
        if(done(i) .or. (.not.ccfok(i)) .or. (ccfred(i).lt.ccflim-1.0) .or. &
             (ccfred(i).lt.ccfred(i+1))) cycle
        if(nqd.eq.1 .or.                                                   &
           (ccfred(i).ge.ccflim .and. abs(f-fgood).gt.10.0*df8)) then

           if(nqd.eq.0) nfreqs0=nfreqs0+1
           if(nqd.eq.1) nfreqs1=nfreqs1+1

           call timer('softsym ',0)
           fpk=1000.0 + df3*(i-1)
           call softsym(c0,npts8,nsps8,newdat,fpk,syncpk,snrdb,xdt,freq,   &
                drift,i1SoftSymbols)

           call timer('softsym ',1)

           call timer('decode9 ',0)
           call decode9(i1SoftSymbols,limit,nlim,msg)
           call timer('decode9 ',1)

           sync=(syncpk+1)/4.0
           if(sync.lt.0.0 .or. snrdb.lt.dblim-2.0) sync=0.0
           nsync=sync
           if(nsync.gt.10) nsync=10
           nsnr=nint(snrdb)
           ndrift=nint(drift/df3)

           write(38,3002) nutc,nsnr,i,freq,ccfred(i),nlim,msg
3002       format(i4.4,i5,i6,2f8.1,i9,2x,a22)

           if(msg.ne.'                      ') then
              if(nqd.eq.0) ndecodes0=ndecodes0+1
              if(nqd.eq.1) ndecodes1=ndecodes1+1

              write(*,fmt) nutc,nsync,nsnr,xdt,freq,ndrift,msg
              write(13,fmt) nutc,nsync,nsnr,xdt,freq,ndrift,msg
!              write(14,1014) nutc,nsync,nsnr,xdt,freq,ndrift,ccfred(i),nlim,msg
!1014          format(i4.4,i4,i5,f6.1,f8.0,i4,f9.1,i9,3x,a22)

              iaa=max(1,i-3)
              ibb=min(NSMAX,i+11)
              fgood=f
              nsynced=1
              ndecoded=1
              ccfok(iaa:ibb)=.false.
              done(iaa:ibb)=.true.              
              call flush(6)
           endif
        endif
     enddo
     call flush(6)
     if(nagain.ne.0) exit
  enddo

  write(*,1010) nsynced,ndecoded
1010 format('<DecodeFinished>',2i4)
  call flush(6)
  close(13)
!  call flush(14)

  call timer('decoder ',1)
  if(nstandalone.eq.0) call timer('decoder ',101)

  call system_clock(iclock,iclock_rate,iclock_max)
  write(39,3001) nutc,nfreqs1,nfreqs0,ndecodes1,ndecodes0+ndecodes1,       &
       float(iclock-iclock0)/iclock_rate
3001 format(5i8,f10.3)
  call flush(38)
  call flush(39)

  return
end subroutine decoder
