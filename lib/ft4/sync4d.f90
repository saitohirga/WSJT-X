subroutine sync4d(cd0,i0,ctwk,itwk,sync)

! Compute sync power for a complex, downsampled FT4 signal.
! 20 samples per symbol

  include 'ft4_params.f90'
  parameter(NP=NMAX/16)
  complex cd0(0:NP-1)
  complex csync(80)
  complex csync2(80)
  complex ctwk(80)
  complex z1,z2,z3
  logical first
  integer icos4(0:3)
  data icos4/0,1,3,2/
  data first/.true./
  save first,twopi,fs2,dt2,taus,baud,csync

  p(z1)=real(z1)**2 + aimag(z1)**2          !Statement function for power

! Set some constants and compute the csync array.  
  if( first ) then
    twopi=8.0*atan(1.0)
    fs2=12000.0/NDOWN                       !Sample rate after downsampling
    dt2=1/fs2                               !Corresponding sample interval
    taus=20*dt2                             !Symbol duration
    baud=1.0/taus                           !Keying rate
    k=1
    phi=0.0
    do i=0,3
!      dphi=(twopi/2.0)*(2*icos4(i)-3)*baud*dt2  
      dphi=twopi*icos4(i)*baud*dt2  
      do j=1,20
        csync(k)=cmplx(cos(phi),sin(phi)) !Waveform for 7x7 Costas array
        phi=mod(phi+dphi,twopi)
        k=k+1
      enddo
    enddo
    first=.false.
  endif

  sync=0
  i1=i0                            !three Costas arrays
  i2=i0+36*20-1
  i3=i0+72*20-1
  csync2=csync
  if(itwk.eq.1) csync2=ctwk*csync2      !Tweak the frequency
  if(i1.ge.0 .and. i1+79.le.NP-1) z1=sum(cd0(i1:i1+79)*conjg(csync2))
  if(i2.ge.0 .and. i2+79.le.NP-1) z2=sum(cd0(i2:i2+79)*conjg(csync2))
  if(i3.ge.0 .and. i3+79.le.NP-1) z3=sum(cd0(i3:i3+79)*conjg(csync2))
  sync = sync + p(z1) + p(z2) + p(z3)

  return
end subroutine sync4d
