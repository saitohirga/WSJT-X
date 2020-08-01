subroutine sync66(c0,f0,jpk,sync)

! Use the sync vector to find xdt (and improved f0 ?)
  
  PARAMETER (NMAX=15*6000)
  parameter (NSPS=960)                       !Samples per symbol at 6000 Hz
  complex c0(0:NMAX-1)                       !Complex data at 6000 S/s
  complex csync0(0:NSPS-1)
  complex csync1(0:NSPS-1)
  complex z
  integer b11(11)                            !Barker 11 code
  data b11/1,1,1,0,0,0,1,0,0,1,0/            !Barker 11 definition
  data mode66z/-1/
  save

  twopi=8.0*atan(1.0)
  baud=6000.0/NSPS
  dt=1.0/6000.0

  dphi0=twopi*f0**dt
  dphi1=twopi*(f0+baud)*dt
  phi0=0.
  phi1=0.

  do i=0,NSPS-1                           !Compute csync for f0 and f0+baud
     csync0(i)=cmplx(cos(phi0),sin(phi0))
     csync1(i)=cmplx(cos(phi1),sin(phi1))
     phi0=phi0 + dphi0
     phi1=phi1 + dphi1
     if(phi0.gt.twopi) phi0=phi0-twopi
     if(phi1.gt.twopi) phi1=phi1-twopi
  enddo

  sqmax=0.
  jstep=NSPS/8  
  do j0=0,6000,jstep
     sq=0.
     do k=1,22
        i=k
        if(i.gt.11) i=i-11
        j1=j0 + 4*(k-1)*NSPS
        if(b11(i).eq.0) then
           z=dot_product(c0(j1:j1+NSPS-1),csync0)
        else
           z=dot_product(c0(j1:j1+NSPS-1),csync1)
        endif
        z=0.001*z
        sq=sq + real(z)**2 + aimag(z)**2
     enddo
     write(52,3052) j0/6000.0,sq,j0,j1
3052 format(f10.6,f12.3,2i8)
     if(sq.gt.smax) then
        smax=sq
        jpk=j0
     endif
  enddo
  sync=smax

  return
end subroutine sync66
