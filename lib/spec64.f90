subroutine spec64(c0,npts2,mode64,jpk,s3a)

  parameter (NSPS=2304)                      !Samples per symbol at 4000 Hz
  complex c0(0:360000)                       !Complex spectrum of dd()
  complex cs(0:NSPS-1)                       !Complex symbol spectrum
  real s3a(0:63,1:63)                        !Synchronized symbol spectra

  nfft4=221184
  c0(npts2:)=0.
  call four2a(c0,nfft4,1,-1,1)             !Forward c2c
  ndown=16/mode64
  nfft5=nfft4/ndown
  npts3=npts2/ndown
  call four2a(c0,nfft5,1,1,1)              !Inverse c2c, downsampled

  nfft6=nsps/ndown
  fsample=4000.0/ndown
  df=fsample/nfft6
  jpkd=nint(float(jpk)/ndown)
  do j=1,63
     jj=j+7                                !Skip first Costas array
     if(j.ge.32) jj=j+14                   !Skip middle Costas array
     ja=jpkd + (jj-1)*nfft6
     jb=ja+nfft6-1
     cs(0:nfft6-1)=1.3e-8*c0(ja:jb)
     call four2a(cs,nfft6,1,-1,1)
     ia=-mode64/2 - mode64
     do ii=0,63
        ia=ia+mode64
        ib=ia+mode64-1
        s=0.
        do i=ia,ib
           if(i.ge.0) then
              s=s + real(cs(i))**2 + aimag(cs(i))**2
           else
              s=s + real(cs(nfft6+i))**2 + aimag(cs(nfft6+i))**2
           endif
        enddo
        s3a(ii,j)=s/mode64
     enddo
  enddo

  return
end subroutine spec64
