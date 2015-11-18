subroutine hspec(id2,k,ingain,green,s,jh)

! Input:
!  k         pointer to the most recent new data

! Output:
!  green()   power
!  s()       spectrum for horizontal spectrogram
!  jh        index of most recent data in green(), s()

  parameter (JZ=703)
  integer*2 id2(0:120*12000-1)
  real green(0:JZ-1)
  real s(0:63,0:JZ-1)
  real x(512)
  complex cx(0:256)
  data rms/999.0/,k0/99999999/
  equivalence (x,cx)
  save ja,rms0

  gain=10.0**(0.1*ingain)
  nfft=512
  if(k.gt.30*12000) go to 900
  if(k.lt.nfft) then       
     jh=0
     go to 900                                 !Wait for enough samples to start
  endif

  if(k.lt.k0) then                             !Start a new data block
     ja=0
     jh=-1
     rms0=0.0
  endif

  do iblk=1,7
     if(jh.lt.JZ-1) jh=jh+1
     jb=ja+nfft-1
     x=id2(ja:jb)
     sq=dot_product(x,x)
     rms=sqrt(gain*sq/nfft)
     green(jh)=0.
     if(rms.gt.0.0) green(jh)=20.0*log10(0.5*(rms0+rms))
     rms0=rms
     call four2a(x,nfft,1,-1,0)                   !Real-to-complex FFT
     df=12000.0/nfft
     fac=(1.0/nfft)**2
     do i=1,64
        j=2*i
        sx=real(cx(j))**2 + aimag(cx(j))**2 + real(cx(j-1))**2 +        &
             aimag(cx(j-1))**2
        s(i-1,jh)=fac*gain*sx
     enddo
     if(ja+2*nfft.gt.k) exit
     ja=ja+nfft
  enddo
  k0=k

900 return
end subroutine hspec
