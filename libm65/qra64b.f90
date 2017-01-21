subroutine qra64b(nutc,nqd,fcenter,nfcal,ikhz,mousedf,ntol,xpol,    &
     mycall_12,hiscall_12,hisgrid_6,mode64,nwrite_qra64)

  parameter (NFFT1=5376000)              !56*96000
  parameter (NFFT2=336000)               !56*6000 (downsampled by 1/16)
  complex ca(NFFT1),cb(NFFT1)            !FFTs of raw x,y data
  complex cx(0:NFFT2-1),cy(0:NFFT2-1)
  logical xpol
  real*8 fcenter
  character*12 mycall_12,hiscall_12
  character*6 hisgrid_6
  common/cacb/ca,cb
  data nzap/3/

  open(17,file='red.dat',status='unknown')
  df=96000.0/NFFT1
  ikhz0=nint(1000.0*(fcenter-int(fcenter)))
  k0=((ikhz-ikhz0+48.0+1.27)*1000.0+nfcal)/df

  nh=nfft2/2
  if(k0.lt.nh .or. k0.gt.NFFT1-nh) go to 900
  
  fac=1.0/NFFT2
  cx(0:nh)=ca(k0:k0+nh)
  cx(nh+1:NFFT2-1)=ca(k0-nh+1:k0-1)
  cx=fac*cx
  cy(0:nh)=cb(k0:k0+nh)
  cy(nh+1:NFFT2-1)=cb(k0-nh+1:k0-1)
  cy=fac*cy

!  write(60) cx,cy,nutc,nqd,ikhz,mousedf,ntol,xpol,mycall_12,           &
!       hiscall_12,hisgrid_6

  if(nzap.gt.0) call qra64zap(cx,cy,xpol,nzap)

! Transform back to time domain with sample rate 6000 Hz.
  call four2a(cx,NFFT2,1,-1,1)
  call four2a(cy,NFFT2,1,-1,1)

  call qra64c(cx,cy,nutc,nqd,ikhz,mousedf,ntol,xpol,mycall_12,    &
       hiscall_12,hisgrid_6,mode64,nwrite_qra64)
  close(17)
  
900 return
end subroutine qra64b
