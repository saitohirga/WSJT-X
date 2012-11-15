subroutine decoder(ntrSeconds,ndepth,nRxLog,c00)

! Decoder for JT9.

  parameter (NMAX=1800*12000)        !Total sample intervals per 30 minutes
  parameter (NDMAX=1800*1500)        !Sample intervals at 1500 Hz rate
  parameter (NSMAX=22000)            !Max length of saved spectra
  character*22 msg
  character*33 line
  character*80 fmt
  real*4 ccfred(NSMAX)
  integer*1 i1SoftSymbols(207)
  integer*2 id2
  integer ii(1)
  complex c0(NDMAX),c00(NDMAX)
  common/jt9com/ss0(184,NSMAX),savg(NSMAX),id2(NMAX),nutc0,ndiskdat,    &
       ntr,nfqso,newdat,npts80,nfb,ntol,kin,nsynced,ndecoded
  common/jt9comB/ss(184,NSMAX),c0
  common/tracer/limtrace,lu
  logical first
  data first/.true./
  save

  if(first) then
     limtrace=0
     lu=12
     open(12,file='timer.out',status='unknown')
     open(14,file='wsjtx_rx.log',status='unknown',position='append')
     first=.false.
  endif

  call timer('decoder ',0)

  if(newdat.ne.0) then
     ss=ss0
     c0=c00
     nutc=nutc0
     npts8=npts80
  endif

  ntrMinutes=ntrSeconds/60
  newdat=1
  nsynced=0
  ndecoded=0
  limit=1000
  if(ndepth.ge.2) limit=20000
  if(ndepth.ge.3) limit=100000

  nsps=0
  if(ntrMinutes.eq.1) then
     nsps=6912
     df3=1500.0/2048.0
     fmt='(i4.4,i4,i5,f6.1,f8.0,f6.1,3x,a22,5x,i6)'
  else if(ntrMinutes.eq.2) then
     nsps=15360
     df3=1500.0/2048.0
     fmt='(i4.4,i4,i5,f6.1,f8.1,f6.2,3x,a22,5x,i6)'
  else if(ntrMinutes.eq.5) then
     nsps=40960
     df3=1500.0/6144.0
     fmt='(i4.4,i4,i5,f6.1,f8.1,f6.2,3x,a22,5x,i6)'
  else if(ntrMinutes.eq.10) then
     nsps=82944
     df3=1500.0/12288.0
     fmt='(i4.4,i4,i5,f6.1,f8.2,f6.2,3x,a22,5x,i6)'
  else if(ntrMinutes.eq.30) then
     nsps=252000
     df3=1500.0/32768.0
     fmt='(i4.4,i4,i5,f6.1,f8.2,f6.2,3x,a22,5x,i6)'
  endif
  if(nsps.eq.0) stop 'Error: bad TRperiod'    !Better: return an error code###

  kstep=nsps/2
  tstep=kstep/12000.0

  call timer('sync9   ',0)
  call sync9(ss,tstep,df3,ntol,nfqso,ccfred,ia,ib,ipk)  ! Get sync, approx freq
  call timer('sync9   ',1)

  open(13,file='decoded.txt',status='unknown')
  rewind 13
  if(iand(nRxLog,2).ne.0) rewind 14
  if(iand(nRxLog,1).ne.0) then
! Write date and time to lu 14     
  endif

  fgood=0.
  df8=1500.0/(nsps/8)
  sbest=0.

10 continue
  ii=maxloc(ccfred(ia:ib))
  i=ii(1) + ia - 1
  f=(i-1)*df3

  if((i.eq.ipk .or. ccfred(i).ge.3.0) .and. abs(f-fgood).gt.10.0*df8) then
     call timer('spec9   ',0)
     call spec9(c0,npts8,nsps,f,fpk,xdt,snr,i1SoftSymbols)
     call timer('spec9   ',1)

     call timer('decode9 ',0)
     call decode9(i1SoftSymbols,limit,nlim,msg)
     call timer('decode9 ',1)
     sync=ccfred(i) - 2.0
     if(sync.lt.0.0) sync=0.0
     nsync=sync
     if(nsync.gt.10) nsync=10
     nsnr=nint(snr)
     drift=0.0

     if(ccfred(i).gt.sbest .and. fgood.eq.0.0) then
        sbest=ccfred(i)
        write(line,fmt) nutc,nsync,nsnr,xdt,1000.0+fpk,drift
        if(nsync.gt.0) nsynced=1
     endif

     if(msg.ne.'                      ') then
        write(13,fmt) nutc,nsync,nsnr,xdt,1000.0+fpk,drift,msg
        write(14,fmt) nutc,nsync,nsnr,xdt,1000.0+fpk,drift,msg,nlim
        fgood=f
        nsynced=1
        ndecoded=1
     endif
  endif
  i1=max(ia,i-10)
  i2=min(ib,i+10)
  ccfred(i1:i2)=0.
  if(maxval(ccfred(ia:ib)).gt.3.0) go to 10

  if(fgood.eq.0.0) then
     write(13,1020) line
     write(14,1020) line
1020 format(a33)
  endif

  call flush(13)
  call flush(14)
  close(13)

  call timer('decoder ',1)
  call timer('decoder ',101)

  return
end subroutine decoder
