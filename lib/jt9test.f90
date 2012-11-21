program jt9test

! Decoder for JT9.

  parameter (NMAX=1800*12000)        !Total sample intervals per 30 minutes
  parameter (NDMAX=1800*1500)        !Sample intervals at 1500 Hz rate
  parameter (NSMAX=22000)            !Max length of saved spectra
  character*22 msg
  character*33 line
  character*80 fmt,fmt14
  real*4 ccfred(NSMAX)
  integer*1 i1SoftSymbols(207)
  integer ii(1)
  complex c0(NDMAX)
!  common/jt9com/ss0(184,NSMAX),savg(NSMAX),id2(NMAX),nutc0,ndiskdat,    &
!       ntr,nfqso,newdat,npts80,nfb,ntol,kin,nzhsym,nsynced,ndecoded
!  common/jt9comB/ss(184,NSMAX),c0
  common/tracer/limtrace,lu

  limtrace=0
  lu=12
  open(12,file='timer.out',status='unknown')
  open(13,file='decoded.txt',status='unknown')
  open(14,file='wsjtx_rx.log',status='unknown',position='append')
  call timer('decoder ',0)

1 read(61,end=999) ipk,ia,ib,ccfred(ia:ib),nsps,npts8,c0(1:npts8)
  print*,ipk,ia,ib,nsps,npts8
  ntrMinutes=1

  nsynced=0
  ndecoded=0
  limit=200
  if(ndepth.ge.2) limit=2000
  if(ndepth.ge.3) limit=20000

  nsps=0
  if(ntrMinutes.eq.1) then
     nsps=6912
     df3=1500.0/2048.0
     fmt='(i4.4,i4,i5,f6.1,f8.0,f6.1,3x,a22)'
     fmt14='(i4.4,i4,i5,f6.1,f8.0,f6.1,i8,3x,a22)'
  else if(ntrMinutes.eq.2) then
     nsps=15360
     df3=1500.0/2048.0
     fmt='(i4.4,i4,i5,f6.1,f8.1,f6.2,3x,a22)'
     fmt14='(i4.4,i4,i5,f6.1,f8.1,f6.2,i8,3x,a22)'
  else if(ntrMinutes.eq.5) then
     nsps=40960
     df3=1500.0/6144.0
     fmt='(i4.4,i4,i5,f6.1,f8.1,f6.2,3x,a22)' 
     fmt14='(i4.4,i4,i5,f6.1,f8.1,f6.2,i8,3x,a22)'
 else if(ntrMinutes.eq.10) then
     nsps=82944
     df3=1500.0/12288.0
     fmt='(i4.4,i4,i5,f6.1,f8.2,f6.2,3x,a22)'
     fmt14='(i4.4,i4,i5,f6.1,f8.2,f6.2,i8,3x,a22)'
  else if(ntrMinutes.eq.30) then
     nsps=252000
     df3=1500.0/32768.0
     fmt='(i4.4,i4,i5,f6.1,f8.2,f6.2,3x,a22)'
     fmt14='(i4.4,i4,i5,f6.1,f8.2,f6.2,i8,3x,a22)'
  endif
  if(nsps.eq.0) stop 'Error: bad TRperiod'    !Better: return an error code###

  fgood=0.
  df8=1500.0/(nsps/8)
  sbest=0.

10 ii=maxloc(ccfred(ia:ib))
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
        write(14,fmt14) nutc,nsync,nsnr,xdt,1000.0+fpk,drift,nlim,msg
        fgood=f
        nsynced=1
        ndecoded=1
        ccfred(max(ia,i):min(ib,i+8))=0.
     endif
  endif
  ccfred(i)=0.
  if(maxval(ccfred(ia:ib)).gt.3.0) go to 10

  if(fgood.eq.0.0) then
     write(13,1020) line
     write(14,1020) line
1020 format(a33)
  endif

  call flush(13)
  call flush(14)
  go to 1

999 call timer('decoder ',1)
  call timer('decoder ',101)

end program jt9test
