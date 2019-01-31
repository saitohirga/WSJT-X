subroutine sync4d(cd0,i0,ctwk,itwk,sync)

! Compute sync power for a complex, downsampled FT4 signal.

  include 'ft4_params.f90'
  parameter(NP=NMAX/NDOWN,NSS=NSPS/NDOWN)
  complex cd0(0:NP-1)
  complex csync(4*NSS)
  complex csync2(4*NSS)
  complex ctwk(4*NSS)
  complex z1,z2,z3,z4
  logical first
  integer icos4(0:3)
  data icos4/0,1,3,2/
  data first/.true./
  save first,twopi,csync,fac

  p(z1)=real(z1*fac)**2 + aimag(z1*fac)**2          !Statement function for power

  if( first ) then
    twopi=8.0*atan(1.0)
    k=1
    phi=0.0
    do i=0,3
      dphi=twopi*icos4(i)/real(NSS) 
      do j=1,NSS
        csync(k)=cmplx(cos(phi),sin(phi)) 
        phi=mod(phi+dphi,twopi)
        k=k+1
      enddo
    enddo
    first=.false.
    fac=1.0/(4.0*NSS)
  endif

  sync=0
  i1=i0                            !four Costas arrays
  i2=i0+33*NSS
  i3=i0+66*NSS
  i4=i0+99*NSS
  csync2=csync
  if(itwk.eq.1) csync2=ctwk*csync2      !Tweak the frequency
  if(i1.ge.0 .and. i1+4*NSS-1.le.NP-1) z1=sum(cd0(i1:i1+4*NSS-1)*conjg(csync2))
  if(i2.ge.0 .and. i2+4*NSS-1.le.NP-1) z2=sum(cd0(i2:i2+4*NSS-1)*conjg(csync2))
  if(i3.ge.0 .and. i3+4*NSS-1.le.NP-1) z3=sum(cd0(i3:i3+4*NSS-1)*conjg(csync2))
  if(i4.ge.0 .and. i4+4*NSS-1.le.NP-1) z4=sum(cd0(i4:i4+4*NSS-1)*conjg(csync2))
  sync = sync + p(z1) + p(z2) + p(z3) + p(z4)

  return
end subroutine sync4d
