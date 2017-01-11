subroutine qra64b(nutc,ikhz)

  parameter (NFFT1=5376000)              !56*96000
  parameter (NFFT2=336000)               !56*6000 (downsampled by 1/16)
  complex cx(0:NFFT2-1),cy(0:NFFT2-1)
  complex ca(NFFT1),cb(NFFT1)            !FFTs of raw x,y data
  common/cacb/ca,cb

!###
  if(nutc.ne.-999) return
!###
  
  df=96000.0/NFFT1
  k0=(ikhz-75.7)*1000.0/df
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

  write(67) nutc,cx,cy

  return
end subroutine qra64b
