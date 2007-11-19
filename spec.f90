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
  real s(NFFT,NY),savg2(NFFT),tmp(NFFT)
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
  do j=1,nlines
     do n=1,nadd
        k=k+1
        do i=1,NFFT
           s(i,j)=s(i,j) + ss5(k,i)
        enddo
     enddo
  enddo
  call zero(savg2,NFFT)
  do j=1,nlines
     call add(savg2,s(1,j),savg2,NFFT)
  enddo

  ia=0.08*NFFT
  nn=0.84*NFFT
  call pctile(savg2(ia),tmp,nn,45,base)
  base=base/(nadd*nlines)

  newpts=NX*nlines
  do i=newpts+1,NX*NY
     a(i)=a(i-newpts)
     a2(i)=a2(i-newpts)
  enddo

  gain=40*sqrt(nstep(nspeed)/5.0) * 5.0**(0.01*contrast)
  gamma=1.3 + 0.01*contrast
  offset=(brightness+64.0)/2
  fac=20.0/nadd
  fac=fac*(0.1537/base)
  foffset=0.001*(1270+nfcal)
  nbpp=(nfb-nfa)*NFFT/(96.0*NX)  !Bins per pixel in wideband (upper) waterfall
  fselect=mousefqso + foffset
  imid=nint(1000.0*(fselect-125.0+48.0)/df)
  fmid=0.5*(nfa+nfb) + foffset
  imid0=nint(1000.0*(fmid-125.0+48.0)/df) - nbpp/2  !Last term is empirical
  i0=imid-375
  ii0=imid0-375*nbpp
  if(nfullspec.eq.1) then
     nbpp=NFFT/NX
     ii0=0
  endif

  k=0
  do j=nlines,1,-1               !Reverse order so last will be on top
     do i=1,NX
        k=k+1
        n=0
        x=0.
        iia=(i-1)*nbpp + ii0 + 1
        iib=i*nbpp + ii0
        do ii=iia,iib
           x=max(x,s(ii,j))
        enddo
        x=fac*x
        if(x.gt.0.0) n=(2.0*x)**gamma + offset
        n=min(252,max(0,n))
        a(k)=n

!  Now do the lower (zoomed) waterfall with one FFT bin per pixel.
        n=0
        x=fac*s(i0+i-1,j)
        if(x.gt.0.0) n=(3.0*x)**gamma + offset
        n=min(252,max(0,n))
        a2(k)=n

     enddo
  enddo

  return
end subroutine spec
