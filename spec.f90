subroutine spec(brightness,contrast,logmap,ngain,nspeed,a)

  parameter (NX=750,NY=130,NTOT=NX*NY,NFFT=32768)

! Input:
  integer brightness,contrast   !Display parameters
  integer ngain                 !Digital gain for input audio
  integer nspeed                !Scrolling speed index

! Output:
  integer*2 a(NTOT)             !Pixel values for NX x NY array

  logical first
  integer nstep(4)
  integer b0,c0
  real s(NX,NY)
  common/spcom/ss(4,322,NFFT)                !169 MB: half-symbol spectra
  include 'gcom1.f90'
  include 'gcom2.f90'
  include 'gcom3.f90'
  include 'gcom4.f90'
  data first/.true./
  data nstep/16,10,5,3/       !Integration limits
  save

  if(first) then
     df=96000.0/nfft
     call zero(a,NX*NY/2)
     first=.false.
  endif

  nadd=nstep(nspeed)
  nlines=322/nadd
  call zero(s,NX*NY)
  k=0
  ia=9001
  ib=9750
  do j=1,nlines
     k=k+1
     do i=ia,ib
        s(i,j)=s(i,j) + ss(1,k,i) + ss(3,k,i)
     enddo
  enddo

  newpts=NX*nlines
  do i=newpts+1,NX*NY
     a(i)=a(i-newpts)
  enddo

  gain=40*sqrt(nstep(nspeed)/5.0) * 5.0**(0.01*contrast)
  gamma=1.3 + 0.01*contrast
  offset=(brightness+64.0)/2
  k=0
  do j=1,nlines
     do i=ia,ib
        k=k+1
        n=0
        x=s(i,j)
!        if(s(i).gt.0.0 .and. logmap.eq.1) n=gain*log10(0.001*s(i)) &
!             + offset + 20
        if(x.gt.0.0 .and. logmap.eq.0) n=(20.0*x)**gamma + offset
        n=min(252,max(0,n))
        a(k)=n
     enddo
  enddo

  return
end subroutine spec
