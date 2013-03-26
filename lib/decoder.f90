subroutine decoder(ss,c0)

! Decoder for JT9.

  parameter (NMAX=1800*12000)        !Total sample intervals per 30 minutes
  parameter (NDMAX=1800*1500)        !Sample intervals at 1500 Hz rate
  parameter (NSMAX=22000)            !Max length of saved spectra
  real ss(184,NSMAX)
  character*22 msg
  character*33 line
  character*80 fmt
  character*20 datetime
  real*4 ccfred(NSMAX)
  logical ccfok(NSMAX)
  integer*1 i1SoftSymbols(207)
  integer*2 id2
  integer ii(1)
  complex c0(NDMAX)
  complex c1(NDMAX)
  common/npar/nutc,ndiskdat,ntrperiod,nfqso,newdat,npts8,nfa,nfb,ntol,  &
       kin,nzhsym,nsave,nagain,ndepth,nrxlog,nfsample,datetime
  common/tracer/limtrace,lu
  save

  call timer('decoder ',0)

  ntrMinutes=ntrperiod/60
  newdat=1
  nsynced=0
  ndecoded=0
  limit=5000
  ccflim=4.0
  if(ndepth.ge.2) then
     limit=50000
     ccflim=3.0
  endif
  if(ndepth.ge.3) then
     limit=200000
     ccflim=2.5
  endif

  nsps=0
  if(ntrMinutes.eq.1) then
     nsps=6912
     df3=1500.0/2048.0
     fmt='(i4.4,i4,i5,f6.1,f8.0,i4,3x,a22)'
  else if(ntrMinutes.eq.2) then
     nsps=15360
     df3=1500.0/2048.0
     fmt='(i4.4,i4,i5,f6.1,f8.1,i4,3x,a22)'
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

  kstep=nsps/2
  tstep=kstep/12000.0

  call timer('sync9   ',0)
  call sync9(ss,nzhsym,tstep,df3,ntol,nfqso,ccfred,ia,ib,ipk)  !Compute ccfred
  call timer('sync9   ',1)

  ccfok=.false.
  ccfok(max(ipk-1,1):min(ipk+1,NSMAX))=.true.
!  nok=0
  do i=ia+9,ib-25
     t1=ccfred(i)/(sum(ccfred(i-8:i-6)/3.0))
     t2=ccfred(i)/(sum(ccfred(i+23:i+25)/3.0))
     if(t1.ge.ccflim .and. t2.ge.ccflim) ccfok(i)=.true.
!     if(ccfok(i)) nok=nok+1
  enddo
!  write(39,*) nok,(ib-25) - (ia+9) +1
!  call flush(39)

  nRxLog=0
  fgood=0.
  nsps8=nsps/8
  df8=1500.0/nsps8
  sbest=-1.0
  dblim=db(864.0/nsps8) - 26.2
  i1=max(nint((nfqso-1000)/df3 - 10),ia)
  i2=min(nint((nfqso-1000)/df3 + 10),ib)
  ii=maxloc(ccfred(i1:i2))
  i00=ii(1) + i1 - 1

  do j=ia,ib
     i=j
     if(i.eq.ia) i=i00                       !Examine QSO frequency first
     f=(i-1)*df3
     if(.not.ccfok(i)) cycle
     if((i.eq.i00 .or. (ccfred(i).ge.3.0) .and. abs(f-fgood).gt.10.0*df8)) then
        call timer('decode9a',0)
        fpk=1000.0 + df3*(i-1)
        c1(1:npts8)=conjg(c0(1:npts8))
        call decode9a(c1,npts8,nsps8,fpk,syncpk,snrdb,xdt,freq,drift,   &
             i1SoftSymbols)
        call timer('decode9a',1)

        call timer('decode9 ',0)
        call decode9(i1SoftSymbols,limit,nlim,msg)
        call timer('decode9 ',1)
 
        sync=(syncpk-1.0)/2.0
        if(sync.lt.0.0 .or. snrdb.lt.dblim-2.0) sync=0.0
        nsync=sync
        if(nsync.gt.10) nsync=10
        nsnr=nint(snrdb)
        ndrift=nint(drift/df3)
        if(msg.ne.'                      ') then
           write(*,fmt) nutc,nsync,nsnr,xdt,freq,ndrift,msg
           fgood=f
           nsynced=1
           ndecoded=1
!           ccfred(max(ia,i-3):min(ib,i+11))=0.
           ccfok(max(ia,i-3):min(ib,i+11))=.false.
        endif
     endif
  enddo

  write(*,1010) nsynced,ndecoded
1010 format('<DecodeFinished>',2i4)
  call flush(6)

  call timer('decoder ',1)
  if(nstandalone.eq.0) call timer('decoder ',101)

  return
end subroutine decoder
