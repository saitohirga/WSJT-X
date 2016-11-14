subroutine spec64(c0,npts2,mode64,jpk,s3,LL,NN)

  parameter (NSPS=3456)                      !Samples per symbol at 6000 Hz
  complex c0(0:360000)                       !Complex spectrum of dd()
  complex cs(0:NSPS-1)                       !Complex symbol spectrum
  real s3(LL,NN)                             !Synchronized symbol spectra

  nfft6=nsps
  fac=1.0/nfft6
  do j=1,63
     jj=j+7                                  !Skip first Costas array
     if(j.ge.32) jj=j+14                     !Skip middle Costas array
     ja=jpk + (jj-1)*nfft6
     jb=ja+nfft6-1
     cs(0:nfft6-1)=fac*c0(ja:jb)
     call four2a(cs,nfft6,1,-1,1)
     smax=0.
     do ii=1,LL
        i=ii-65
        if(i.lt.0) i=i+nfft6
        s3(ii,j)=real(cs(i))**2 + aimag(cs(i))**2
        if(s3(ii,j).gt.smax) then
           smax=s3(ii,j)
           ipk=ii-65
        endif
     enddo
  enddo

  return
end subroutine spec64
