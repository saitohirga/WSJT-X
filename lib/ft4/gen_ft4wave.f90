subroutine gen_ft4wave(itone,nsym,nsps,fsample,f0,wave,nwave)

  real wave(nwave)
  real pulse(6144)              !512*4*3
  real dphi(0:240000-1)
  integer itone(nsym)
  logical first
  data first/.true./
  save pulse,first,twopi,dt,hmod

  if(first) then
     twopi=8.0*atan(1.0)
     dt=1.0/fsample
     hmod=1.0
! Compute the frequency-smoothing pulse
     do i=1,3*nsps
        tt=(i-1.5*nsps)/real(nsps)
        pulse(i)=gfsk_pulse(1.0,tt)
     enddo
     first=.false.
  endif

! Compute the smoothed frequency waveform.
! Length = (nsym+2)*nsps samples, zero-padded
  dphi_peak=twopi*hmod/real(nsps)
  dphi=0.0 
  do j=1,nsym         
     ib=(j-1)*nsps
     ie=ib+3*nsps-1
     dphi(ib:ie) = dphi(ib:ie) + dphi_peak*pulse(1:3*nsps)*itone(j)
  enddo

! Calculate and insert the audio waveform
  phi=0.0
  dphi = dphi + twopi*f0*dt                          !Shift frequency up by f0
  wave=0.
  k=0
  do j=0,nwave-1
     k=k+1
     wave(k)=sin(phi)
     phi=mod(phi+dphi(j),twopi)
  enddo

! Compute the ramp-up and ramp-down symbols
  wave(1:nsps)=wave(1:nsps) *                                          &
       (1.0-cos(twopi*(/(i,i=0,nsps-1)/)/(2.0*nsps)))/2.0
  k1=(nsym+1)*nsps+1
  wave(k1:k1+nsps-1)=wave(k1:k1+nsps-1) *                              &
       (1.0+cos(twopi*(/(i,i=0,nsps-1)/)/(2.0*nsps)))/2.0

  return
end subroutine gen_ft4wave
