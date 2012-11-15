subroutine peakdt9(c0,npts8,nsps8,istart,foffset,idtpk)

  complex c0(0:npts8-1)
  complex zsum
  include 'jt9sync.f90'

  twopi=8.0*atan(1.0)
  smax=0.
  tstep=0.0625*nsps8/1500.0
  idtmax=2.5/tstep

  f0=foffset
  dphi=twopi*f0/1500.0

  idtstep=4
  if(idtmax.lt.30) idtstep=2
  if(idtmax.lt.15) idtstep=1
  idt1=-idtmax
  idt2=idtmax

10 do idt=idt1,idt2,idtstep
     i0=istart + 0.0625*nsps8*idt
    sum=0.
     do j=1,16
        i1=max(0,(ii(j)-1)*nsps8 + i0)
        i2=min(npts8-1,i1+nsps8-1)
        phi=0.
        zsum=0.
        do i=i1,i2
           if(i.lt.0 .or. i.gt.npts8-1) cycle
           phi=phi + dphi
           zsum=zsum + c0(i)*cmplx(cos(phi),-sin(phi))
        enddo
        sum=sum + real(zsum)**2 + aimag(zsum)**2
     enddo
     if(sum.gt.smax) then
        idtpk=idt
        smax=sum
     endif
  enddo

  if(idtstep.gt.1) then
     idtstep=1
     idt1=idtpk-1
     idt2=idtpk+1
     go to 10
  endif

  return
end subroutine peakdt9
