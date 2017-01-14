subroutine qra64b(nutc,nqd,ikhz,mousedf,ntol,xpol,mycall_12,hiscall_12,   &
     hisgrid_6)

  parameter (NFFT1=5376000)              !56*96000
  parameter (NFFT2=336000)               !56*6000 (downsampled by 1/16)
  complex cx(0:NFFT2-1),cy(0:NFFT2-1)
  complex ca(NFFT1),cb(NFFT1)            !FFTs of raw x,y data
  logical xpol
  character*12 mycall_12,hiscall_12
  character*6 hisgrid_6
  common/cacb/ca,cb

  open(17,file='red.dat',status='unknown')
  df=96000.0/NFFT1
  k0=(ikhz-75.170)*1000.0/df
  nh=nfft2/2
  fac=1.0/NFFT2
  cx(0:nh)=ca(k0:k0+nh)
  cx(nh+1:NFFT2-1)=ca(k0-nh+1:k0-1)
  cx=fac*cx
  cy(0:nh)=cb(k0:k0+nh)
  cy(nh+1:NFFT2-1)=cb(k0-nh+1:k0-1)
  cy=fac*cy

! Transform back to time domain with sample rate 6000 Hz.
  call four2a(cx,NFFT2,1,-1,1)
  call four2a(cy,NFFT2,1,-1,1)

!  write(67) nutc,cx,cy
  call qra64c(cx,cy,nutc,nqd,ikhz,mousedf,ntol,xplo,mycall_12,    &
       hiscall_12,hisgrid_6)
  close(17)
  
  return
end subroutine qra64b
