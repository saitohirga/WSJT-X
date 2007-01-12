subroutine spec(brightness,contrast,logmap,ngain,nspeed,a)

  parameter (NX=750,NY=130,NTOT=NX*NY,NFFT=32768)

! Input:
  integer brightness,contrast   !Display parameters
  integer ngain                 !Digital gain for input audio
  integer nspeed                !Scrolling speed index

! Output:
  integer*2 a(NTOT)             !Pixel values for NX x NY array

!  real a0(NTOT)                 !Save the last NY spectra
  integer nstep(5)
  integer b0,c0
  real s(NFFT)
  common/spcom/ss(4,322,NFFT)                !169 MB: half-symbol spectra
  include 'gcom1.f90'
  include 'gcom2.f90'
  include 'gcom3.f90'
  include 'gcom4.f90'
  data jz/0/                    !Number of spectral lines available
  data nstep/15,10,5,2,1/       !Integration limits
  save

  df=96000.0/nfft
  b0=-999
  c0=-999
  logmap0=-999
  nspeed0=-999
  nmode=2                                  !JT65 mode

  nadd=nstep(nspeed)
  nlines=322/nadd
  j=0
  print*,'A',nspeed,nadd,nlines
  do k=1,nlines
     do i=1,nfft
        s(i)=0.
        do n=1,nadd
           j=j+1
           s(i)=s(i) + ss(1,j,i) + ss(3,j,i)
        enddo
        s(i)=s(i)/nadd
     enddo
     print*,'B',k

!  Compute pixel values 
!     iz=NX
!     logmap=0
!     if(brightness.ne.b0 .or. contrast.ne.c0 .or. logmap.ne.logmap0 .or.    &
!          nspeed.ne.nspeed0 .or. nlines.gt.1) then
     iz=NTOT
     gain=40*sqrt(nstep(nspeed)/5.0) * 5.0**(0.01*contrast)
     gamma=1.3 + 0.01*contrast
     offset=(brightness+64.0)/2
     b0=brightness
     c0=contrast
     logmap0=logmap
     nspeed0=nspeed
     ia=10001
     ib=10750

     do i=ia,ib
        n=0
        if(s(i).gt.0.0 .and. logmap.eq.1) n=gain*log10(0.001*s(i)) &
             + offset + 20
        if(s(i).gt.0.0 .and. logmap.eq.0) n=(0.01*s(i))**gamma + offset
        n=min(252,max(0,n))
        a(i)=n
     enddo
     print*,'C'
  enddo
  print*,'D'

  return
end subroutine spec
