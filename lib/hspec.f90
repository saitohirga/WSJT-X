subroutine hspec(id2,k,nutc0,ntrpdepth,nrxfreq,ntol,bmsk144,ingain,   &
     green,s,jh,line1)

! Input:
!  k         pointer to the most recent new data

! Output:
!  green()   power
!  s()       spectrum for horizontal spectrogram
!  jh        index of most recent data in green(), s()

  parameter (JZ=703)
  character*80 line1
  integer*2 id2(0:120*12000-1)
  logical*1 bmsk144
  real green(0:JZ-1)
  real s(0:63,0:JZ-1)
  real x(512)
  complex cx(0:256)
  data rms/999.0/,k0/99999999/
  equivalence (x,cx)
  save ja,rms0

  ndepth=ntrpdepth/1000
  ntrperiod=ntrpdepth - 1000*ndepth
  gain=10.0**(0.1*ingain)
  nfft=512
  nstep=nfft
  nblks=7
  if(ntrperiod.lt.30) then
     nstep=256
     nblks=14
  endif

  if(k.gt.30*12000) go to 900
  if(k.lt.nfft) then       
     jh=0
     go to 900                                 !Wait for enough samples to start
  endif

  if(k.lt.k0) then                             !Start a new data block
     ja=-nstep
     jh=-1
     rms0=0.0
  endif

  do iblk=1,nblks
     if(jh.lt.JZ-1) jh=jh+1
     ja=ja+nstep
     jb=ja+nfft-1
     x=id2(ja:jb)
     sq=dot_product(x,x)
     rms=sqrt(gain*sq/nfft)
     green(jh)=0.
     if(rms.gt.0.0) green(jh)=20.0*log10(rms)
     call four2a(x,nfft,1,-1,0)                   !Real-to-complex FFT
     df=12000.0/nfft
     fac=(1.0/nfft)**2
     do i=1,64
        j=2*i
        sx=real(cx(j))**2 + aimag(cx(j))**2 + real(cx(j-1))**2 +        &
             aimag(cx(j-1))**2
        s(i-1,jh)=fac*gain*sx
     enddo
!     call smo121(s(0,jh),64)   !### Good idea, or not? ###
     if(ja+2*nfft.gt.k) exit
  enddo
  k0=k

!###
  if(bmsk144) then
     if(k.ge.7168) then
        tsec=(k-7168)/12000.0
        call mskrtd(id2(k-7168+1:k),nutc0,tsec,ntol,nrxfreq,line1)
     endif
  endif
!###

900 return
end subroutine hspec
