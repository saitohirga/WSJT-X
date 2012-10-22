subroutine spec9(c0,npts8,nsps,fpk0,fpk,xdt,i1SoftSymbols)

  parameter (MAXFFT=31500)
  complex c0(0:npts8-1)
  complex c1(0:2700000)
  complex c2(0:2700000)
  real ssym(0:7,69)
  complex c(0:MAXFFT-1)
  integer*1 i1SoftSymbolsScrambled(207)
  integer*1 i1SoftSymbols(207)
  integer ig(0:7)
  data ig/0,1,3,2,7,6,4,5/             !Gray code removal
  include 'jt9sync.f90'
  save

! Fix up the data in c0()
  sum=0.
  do i=0,npts8-1
     sum=sum + real(c0(i))**2 + aimag(c0(i))**2
  enddo
  rms=sqrt(sum/npts8)
  fac=1.0/rms
  twopi=8.0*atan(1.0)
  phi=0.
  dphi=twopi*500.0/1500.0
  do i=0,npts8-1
     phi=phi+dphi
     if(phi.gt.twopi) phi=phi-twopi
     if(phi.lt.-twopi) phi=phi+twopi
     c1(i)=fac*cmplx(aimag(c0(i)),real(c0(i)))*cmplx(cos(phi),sin(phi))
  enddo

!###
  c2(0:npts8-1)=c1(0:npts8-1)
  c2(npts8:)=0.
  nfft4=256*1024
  df4=1500.0/nfft4
  call four2a(c2,nfft4,1,-1,1)
  rewind 71
  do i=0,nfft4/2
     freq=i*df4
     p=1.e-5*(real(c2(i))**2 + aimag(c2(i))**2)
     write(71,3001) freq,p
3001 format(2f15.3)
  enddo
  call flush(71)
!###

  nsps8=nsps/8
  foffset=fpk0
  istart=1520

  call peakdf9(c1,npts8,nsps8,istart,foffset,idf)
  fpk=fpk0 + idf*0.1*1500.0/nsps8
  foffset=foffset + idf*0.1*1500.0/nsps8
  call peakdt9(c1,npts8,nsps8,istart,foffset,idt)
  istart=istart + 0.0625*nsps8*idt
  xdt=istart/1500.0 - 1.0
!  write(*,3002)  0.0625*nsps8*idt/1500.0,idf*0.1*1500.0/nsps8
!3002 format(2f8.2)


  fshift=foffset
  twopi=8.0*atan(1.0)
  dphi=twopi*fshift/1500.0

  nfft=nsps8
  nsym=min((npts8-istart)/nsps8,85)

  k=0
  do j=1,nsym
     if(isync(j).eq.1) cycle
     k=k+1
     ia=(j-1)*nsps8 + istart
     ib=ia+nsps8-1
     c(0:nfft-1)=c1(ia:ib)

     phi=0.
     do i=0,nfft-1
        phi=phi + dphi
        c(i)=c(i) * cmplx(cos(phi),-sin(phi))
     enddo

     call four2a(c,nfft,1,-1,1)
     do i=0,nfft-1
        sx=real(c(i))**2 + aimag(c(i))**2
        if(i.ge.1 .and. i.le.8) ssym(ig(i-1),k)=sx
     enddo
  enddo

  m0=3
  ntones=8
  k=0
  do j=1,69
     do m=m0-1,0,-1                   !Get bit-wise soft symbols
        n=2**m
        r1=0.
        r2=0.
        do i=0,ntones-1
           if(iand(i,n).ne.0) then
              r1=max(r1,ssym(i,j))
           else
              r2=max(r2,ssym(i,j))
           endif
        enddo
        k=k+1
        i1SoftSymbolsScrambled(k)=min(127,max(-127,nint(10.0*(r1-r2)))) + 128
     enddo
  enddo

  call interleave9(i1SoftSymbolsScrambled,-1,i1SoftSymbols)

  return
end subroutine spec9
