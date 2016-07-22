subroutine qra64a(dd0,nutc,nf1,nf2,nfqso,ntol,mycall_12,hiscall_12,   &
     hisgrid_6,sync,nsnr,dtx,nfreq,decoded,nft)

  use packjt
  parameter (NFFT=2*6912,NZ=5760,NMAX=60*12000)
  character decoded*22
  character*12 mycall_12,hiscall_12
  character*6 mycall,hiscall,hisgrid_6
  character*4 hisgrid
  logical ltext
  integer*8 count0,count1,clkfreq
  integer icos7(0:6)
  integer dat4(12)
  real dd0(NMAX),dd(NMAX)
  real s(NZ)
  real savg(NZ)
  real blue(0:25)
  real red(NZ)
  real ss(NZ,194)
  real ccf(NZ,0:25)
  real s3(0:63,1:63)
  real s3a(0:63,1:63)  
  data icos7/2,5,6,0,4,1,3/                            !Costas 7x7 pattern
  data nc1z/-1/,nc2z/-1/,ng2z/-1/
!  common/qra64com/ss(NZ,194),ccf(NZ,0:25),s3(0:63,1:63),s3a(0:63,1:63)
  save

!  write(60) dd0

  decoded='                      '
  nft=99
  nsnr=-30
  nsps=6912
  istep=nsps/2
  nsteps=52*12000/istep - 2
  df=12000.0/NFFT
  call spec64(dd0,-1,s,savg,ss)
  fa=max(nf1,nfqso-ntol)
  fb=min(nf2,nfqso+ntol)
  ia=nint(fa/df)
  ib=nint(fb/df)
  call pctile(savg(ia),ib-ia+1,45,base)
  savg=savg/base - 1.0
  ss=ss/base

  red=-99.
  fac=1.0/sqrt(21.0)
  sync=0.
  do if0=ia,ib
     do j=0,25
        t=-3.0
        do n=0,6
           i=if0 + 2*icos7(n)
           t=t + ss(i,1+2*n+j) + ss(i,1+2*n+j+78) + ss(i,1+2*n+j+154)
        enddo
        ccf(if0,j)=fac*t
        if(ccf(if0,j).gt.red(if0)) then
           red(if0)=ccf(if0,j)
           if(red(if0).gt.sync) then
              sync=red(if0)
              f0=if0*df
!              dtx=j*istep/12000.0 - 1.0
              i0=if0
              j0=j
           endif
        endif
     enddo
  enddo

  write(17) ia,ib,red(ia:ib)
  close(17)

  if0=nint(f0/df)
  nfreq=nint(f0)
  blue(0:25)=ccf(if0,0:25)
  dj=0.
  if(j0.ge.1 .and. j0.le.24) call peakup(blue(j0-1),blue(j0),blue(j0+1),dj)
  xpk=j0 + dj
  dtx=xpk*istep/12000.0 - 1.0
  i=nint(dj*istep)
  if(i.lt.0) then
     dd(1-i:NMAX)=dd0(1:NMAX+i)
     dd(1:-i)=0.0
  else
     dd(1:NMAX-i)=dd0(1+i:NMAX)
     dd(NMAX-i+1:NMAX)=0.0
  endif

! Recompute the symbol spectra, this time aligned for best DT estimate.
  ss=0.
  call spec64(dd,j0,s,savg,ss)

  do i=0,63                                !Copy symbol spectra into s3()
     k=i0 + 2*i
     jj=j0+13
     do j=1,63
        jj=jj+2
        s3(i,j)=ss(k,jj)
        if(j.eq.32) jj=jj+14               !Skip over the middle Costas array
     enddo
  enddo

  if(sync.gt.1.0) snr1=10.0*log10(sync) - 39.0
  nsnr=nint(snr1)
!  write(*,5001) dtx,nint(f0),0,snr1
!5001 format(f6.3,2i6,f7.1)
  maxf1=10
  call sync64(dd0,nf1,nf2,maxf1,dtx,f0,kpk,snr,s3a)
!  write(*,5001) dtx,nint(f0),kpk,snr

  mycall=mycall_12(1:6)                     !### May need fixing ###
  hiscall=hiscall_12(1:6)
  hisgrid=hisgrid_6(1:4)
  call packcall(mycall,nc1,ltext)
  call packcall(hiscall,nc2,ltext)
  call packgrid(hisgrid,ng2,ltext)

  if(nc1.ne.nc1z .or. nc2.ne.nc2z .or. ng2.ne.ng2z) then
     do naptype=0,5
        call qra64_dec(s3,nc1,nc2,ng2,naptype,1,dat4,snr2,irc)
     enddo
     nc1z=nc1
     nc2z=nc2
     ng2z=ng2
  endif

  snr2=-99.
  naptype=4
  call system_clock(count0,clkfreq)
  call qra64_dec(s3,nc1,nc2,ng2,naptype,0,dat4,snr2,irc)
  if(irc.ge.0) then
     call unpackmsg(dat4,decoded)           !Unpack the user message
     call fmtmsg(decoded,iz)
     nft=100 + irc
     nsnr=nint(snr2)
  else
     snr2=0.
  endif
  call system_clock(count1,clkfreq)
  tsec=float(count1-count0)/float(clkfreq)
  write(78,3900) nutc,sync,snr1,snr2,dtx,nfreq,1,irc,tsec,decoded
3900 format(i4.4,3f6.1,f6.2,i5,i2,i3,f6.3,1x,a22)
  flush(78)

  return
end subroutine qra64a

subroutine spec64(dd,j0,s,savg,ss)

  parameter (NFFT=2*6912,NH=NFFT/2,NZ=5760)
  real dd(60*12000)
  real s(NZ)
  real savg(NZ)
  real ss(NZ,194)
  real x(NFFT)
  complex cx(0:NH)
  equivalence (x,cx)

  nsps=6912
  istep=nsps/2
  nsteps=52*12000/istep - 2
  ia=1-istep
  savg=0.
  df=12000.0/NFFT
  mj0=mod(j0,2)
  do j=1,nsteps
     ia=ia+istep
     if(j0.ge.0 .and. mod(j,2).eq.mj0) cycle   !Skip half of FFTs in 2nd pass
     ib=ia+nsps-1
     x(1:nsps)=1.2e-4*dd(ia:ib)
     x(nsps+1:)=0.0
     call four2a(x,nfft,1,-1,0)                !r2c FFT
     do i=1,NZ
        s(i)=real(cx(i))**2 + aimag(cx(i))**2
     enddo
     ss(1:NZ,j)=s
     savg=savg+s
  enddo
  savg=savg/nsteps

  return
end subroutine spec64

include 'sync64.f90'
include 'averms.f90'
