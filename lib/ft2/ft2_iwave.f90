subroutine ft2_iwave(msg37,f0,snrdb,iwave)

! Generate waveform for experimental "FT2" mode 

  use packjt77
  include 'ft2_params.f90'               !Set various constants
  parameter (NWAVE=NN*NSPS)
  character msg37*37,msgsent37*37
  real wave(NMAX)
  integer itone(NN)
  integer*2 iwave(NMAX)                  !Generated full-length waveform
  
  twopi=8.0*atan(1.0)
  fs=12000.0                             !Sample rate (Hz)
  dt=1.0/fs                              !Sample interval (s)
  hmod=0.8                               !Modulation index (MSK=0.5, FSK=1.0)
  tt=NSPS*dt                             !Duration of symbols (s)
  baud=1.0/tt                            !Keying rate (baud)
  bw=1.5*baud                            !Occupied bandwidth (Hz)
  txt=NZ*dt                              !Transmission length (s)
  bandwidth_ratio=2500.0/(fs/2.0)
  sig=sqrt(2*bandwidth_ratio) * 10.0**(0.05*snrdb)
  if(snrdb.gt.90.0) sig=1.0
  txt=NN*NSPS/12000.0

! Source-encode, then get itone():
  itype=1
  call genft2(msg37,0,msgsent37,itone,itype)

  k=0
  phi=0.0 
  do j=1,NN                             !Generate real waveform
     dphi=twopi*(f0*dt+(hmod/2.0)*(2*itone(j)-1)/real(NSPS))
     do i=1,NSPS
        k=k+1
        wave(k)=sig*sin(phi)
        phi=mod(phi+dphi,twopi)
     enddo
  enddo
  kz=k

  peak=maxval(abs(wave(1:kz)))
!  nslots=1
!  if(width.gt.0.0) call filt8(f0,nslots,width,wave)
   
  if(snrdb.lt.90) then
     do i=1,NMAX                   !Add gaussian noise at specified SNR
        xnoise=gran()
        wave(i)=wave(i) + xnoise
     enddo
  endif

  gain=1.0
  if(snrdb.lt.90.0) then
     wave=gain*wave
  else
     datpk=maxval(abs(wave))
     fac=32767.0/datpk
     wave=fac*wave
  endif

  if(any(abs(wave).gt.32767.0)) print*,"Warning - data will be clipped."
  iwave(1:kz)=nint(wave(1:kz))
  
  return
end subroutine ft2_iwave
