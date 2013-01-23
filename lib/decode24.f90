subroutine decode24(dat,npts,dtx,dfx,flip,mode,mode4,decoded,ncount,   &
     deepmsg,qual,submode)

! Decodes JT65 data, assuming that DT and DF have already been determined.

  parameter (MAXAVE=120)
  real dat(npts)                        !Raw data
  character decoded*22,deepmsg*22
  character*12 mycall,hiscall
  character*6 hisgrid
  character*72 c72
  character submode*1
  real*8 dt,df,phi,f0,dphi,twopi,phi1,dphi1
  complex*16 cz,cz1,c0,c1
  integer*1 symbol(207)
  real*4 rsymbol(207,7)
  real*4 sym(207)
  integer nsum(7)
  integer*1 data1(13)                   !Decoded data (8-bit bytes)
  integer   data4a(9)                   !Decoded data (8-bit bytes)
  integer   data4(12)                   !Decoded data (6-bit bytes)
  integer amp,delta
  integer mettab(0:255,0:1)             !Metric table
  integer nch(7)
  integer npr2(207)
!  common/ave/ppsave(64,63,MAXAVE),nflag(MAXAVE),nsave,iseg(MAXAVE)
  data mode0/-999/
  data nsum/7*0/,rsymbol/1449*0.0/
  data npr2/                                                         &
       0,0,0,0,1,1,0,0,0,1,1,0,1,1,0,0,1,0,1,0,0,0,0,0,0,0,1,1,0,0,  &
       0,0,0,0,0,0,0,0,0,0,1,0,1,1,0,1,1,0,1,0,1,1,1,1,1,0,1,0,0,0,  &
       1,0,0,1,0,0,1,1,1,1,1,0,0,0,1,0,1,0,0,0,1,1,1,1,0,1,1,0,0,1,  &
       0,0,0,1,1,0,1,0,1,0,1,0,1,0,1,1,1,1,1,0,1,0,1,0,1,1,0,1,0,1,  &
       0,1,1,1,0,0,1,0,1,1,0,1,1,1,1,0,0,0,0,1,1,0,1,1,0,0,0,1,1,1,  &
       0,1,1,1,0,1,1,1,0,0,1,0,0,0,1,1,0,1,1,0,0,1,0,0,0,1,1,1,1,1,  &
       1,0,0,1,1,0,0,0,0,1,1,0,0,0,1,0,1,1,0,1,1,1,1,0,1,0,1/

  data nch/1,2,4,9,18,36,72/
  save mettab,mode0,nsum,rsymbol

  if(mode.ne.mode0) call getmet24(mode,mettab)
  mode0=mode
  twopi=8*atan(1.d0)
  dt=2.d0/11025             !Sample interval (2x downsampled data)
  df=11025.d0/2520.d0
  nsym=206
  amp=15
  istart=nint(dtx/dt)              !Start index for synced FFTs
  if(istart.lt.0) istart=0
  nchips=0
  ich=0
  qbest=0.
  deepmsg='                      '
  ichbest=-1

! Should amp be adjusted according to signal strength?

! Compute soft symbols using differential BPSK demodulation
  c0=0.                                !### C0=amp ???
  k=istart
  phi=0.d0
  phi1=0.d0

40 ich=ich+1
  nchips=nch(ich)
  nspchip=1260/nchips
  k=istart
  phi=0.d0
  phi1=0.d0
  fac2=1.e-8 * sqrt(float(mode4))
  do j=1,nsym+1
     if(flip.gt.0.0) then
        f0=1270.46 + dfx + (npr2(j)-1.5)*mode4*df
        f1=1270.46 + dfx + (2+npr2(j)-1.5)*mode4*df
     else
        f0=1270.46 + dfx + (1-npr2(j)-1.5)*mode4*df
        f1=1270.46 + dfx + (3-npr2(j)-1.5)*mode4*df
     endif
     dphi=twopi*dt*f0
     dphi1=twopi*dt*f1
     sq0=0.
     sq1=0.
     do nc=1,nchips
        phi=0.d0
        phi1=0.d0
        c0=0.
        c1=0.
        do i=1,nspchip
           k=k+1
           phi=phi+dphi
           phi1=phi1+dphi1
           cz=dcmplx(cos(phi),-sin(phi))
           cz1=dcmplx(cos(phi1),-sin(phi1))
           if(k.le.npts) then
              c0=c0 + dat(k)*cz
              c1=c1 + dat(k)*cz1
           endif
        enddo
        sq0=sq0 + real(c0)**2 + aimag(c0)**2
        sq1=sq1 + real(c1)**2 + aimag(c1)**2
     enddo
     sq0=fac2*sq0
     sq1=fac2*sq1
     rsym=amp*(sq1-sq0)
     r=rsym+128.
     if(r.gt.255.0) r=255.0
     if(r.lt.0.0) r=0.0
     i4=nint(r)
     if(i4.gt.127) i4=i4-256
     if(j.ge.1) then
        symbol(j)=i4
!        rsymbol(j,ich)=rsymbol(j,ich) + rsym
        rsymbol(j,ich)=rsym
        sym(j)=rsym
     endif
  enddo
  
!###  The following does simple message averaging:
!  nsum(ich)=nsum(ich)+1
!  do j=1,207
!     sym(j)=rsymbol(j,ich)/nsum(ich)
!     r=sym(j) + 128.
!     if(r.gt.255.0) r=255.0
!     if(r.lt.0.0) r=0.0
!     i4=nint(r)
!     if(i4.gt.127) i4=i4-256
!     symbol(j)=i4
!  enddo
!###
  
  nbits=72+31
  delta=50
  limit=100000
  ncycles=0
  ncount=-1
  call interleave24(symbol(2),-1)         !Remove the interleaving

  call fano232(symbol(2),nbits,mettab,delta,limit,data1,ncycles,metric,ncount)
  nlim=ncycles/nbits

!### Try deep search
  qual=0.
  neme=1
  mycall='VK7MO'
  hiscall='W5LUA'
  hisgrid='EM13'
  call deep24(sym(2),neme,flip,mycall,hiscall,hisgrid,decoded,qual)
  if(qual.gt.qbest) then
     qbest=qual
     deepmsg=decoded
     ichbest=ich
  endif
!###

  if(ncount.ge.0) go to 100
  if(mode.eq.7 .and. nchips.lt.mode4) go to 40

100 do i=1,9
     i4=data1(i)
     if(i4.lt.0) i4=i4+256
     data4a(i)=i4
  enddo
  write(c72,1100) (data4a(i),i=1,9)
1100 format(9b8.8)
  read(c72,1102) data4
1102 format(12b6)

  decoded='                      '
  submode=' '
  if(ncount.ge.0) then
     call unpackmsg(data4,decoded)
     submode=char(ichar('A')+ich-1)
  else
     decoded=deepmsg
     submode=char(ichar('A')+ichbest-1)
     qual=qbest
  endif
  if(decoded(1:6).eq.'000AAA') then
     decoded='***WRONG MODE?***'
     ncount=-1
  endif

! Save symbol spectra for possible decoding of average.

  return
end subroutine decode24
