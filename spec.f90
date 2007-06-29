subroutine spec(brightness,contrast,ngain,nspeed,a,a2)

  parameter (NX=750,NY=130,NTOT=NX*NY)

! Input:
  integer brightness,contrast   !Display parameters
  integer ngain                 !Digital gain for input audio
  integer nspeed                !Scrolling speed index

! Output:
  integer*2 a(NTOT)             !Pixel values for NX x NY array
  integer*2 a2(NTOT)            !Pixel values for NX x NY array

  logical first
  integer nstep(5)
  integer b0,c0

!  Could save memory by doing the averaging-by-7 (or 10?) of ss5 in symspec.
  include 'spcom.f90'
  real s(NFFT,NY)
  include 'gcom1.f90'
  include 'gcom2.f90'
  include 'gcom3.f90'
  include 'gcom4.f90'
  data first/.true./
  data nstep/28,20,14,10,7/       !Integration limits
  save

  if(first) then
     df=96000.0/nfft
     call zero(a,NX*NY/2)
     call zero(a2,NX*NY/2)
     first=.false.
  endif

  nadd=nstep(nspeed)
  nlines=322/nadd
  call zero(s,NFFT*NY)
  k=0
  fselect=mousefqso + 1.6
  imid=nint(1000.0*(fselect-125.0+48.0)/df)
  ia=imid-374
  ib=ia+749

  do j=1,nlines
     do n=1,nadd
        k=k+1
        do i=1,NFFT
           s(i,j)=s(i,j) + ss5(k,i)
        enddo
     enddo
  enddo

  newpts=NX*nlines
  do i=newpts+1,NX*NY
     a(i)=a(i-newpts)
     a2(i)=a2(i-newpts)
  enddo

  gain=40*sqrt(nstep(nspeed)/5.0) * 5.0**(0.01*contrast)
  gamma=1.3 + 0.01*contrast
  offset=(brightness+64.0)/2
  k=0
  fac=20.0/nadd
  nbpp=NFFT/NX                        !Bins per pixel in wide waterfall
  do j=nlines,1,-1                    !Reverse order so last will be on top
     do i=1,NX
        k=k+1

        n=0
        x=0.
        do ii=(i-1)*nbpp+1,i*nbpp
           x=max(x,s(ii,j))
        enddo
        x=fac*x
        if(x.gt.0.0) n=(2.0*x)**gamma + offset
        n=min(252,max(0,n))
        a(k)=n

        n=0
        x=fac*s(ia+i-1,j)
        if(x.gt.0.0) n=(3.0*x)**gamma + offset
        n=min(252,max(0,n))
        a2(k)=n

     enddo
  enddo

  return
end subroutine spec
