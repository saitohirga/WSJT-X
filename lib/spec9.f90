subroutine spec9(c0,npts8,nsps,fpk0,fpk,xdt,snrdb,i1SoftSymbols)

  parameter (MAXFFT=31500)
  complex c0(0:npts8-1)
  complex c1(0:2700000)
  real*4 ssym(0:7,69)
  real*4 sx(0:31500-1)
  complex c(0:MAXFFT-1)
  integer*1 i1SoftSymbolsScrambled(207)
  integer*1 i1SoftSymbols(207)
  integer*1 i1
  integer ig(0:7)
  equivalence (i1,i4)
  data ig/0,1,3,2,7,6,4,5/             !Gray code removal
  include 'jt9sync.f90'

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

  nsps8=nsps/8
  foffset=fpk0
  istart=1520

  call timer('peakdt9 ',0)
  call peakdt9(c1,npts8,nsps8,istart,foffset,idt)
  call timer('peakdt9 ',1)
  istart=istart + 0.0625*nsps8*idt
  xdt=istart/1500.0 - 1.0

  call timer('peakdf9 ',0)
  call peakdf9(c1,npts8,nsps8,istart,foffset,idf)
  call timer('peakdf9 ',1)

  fpk=fpk0 + idf*0.1*1500.0/nsps8
  foffset=foffset + idf*0.1*1500.0/nsps8

  twopi=8.0*atan(1.0)
  dphi=twopi*foffset/1500.0
  nfft=nsps8
  nsym=min((npts8-istart)/nsps8,85)

  k=0
  do j=1,nsym
     if(isync(j).eq.1) cycle
     k=k+1
     ia=(j-1)*nsps8 + istart
     ib=ia+nsps8-1

!     c(0:nfft-1)=c1(ia:ib)
     do i=0,nfft-1
        c(i)=0.
        if(ia+i.ge.0 .and. ia+i.lt.2700000-1) c(i)=c1(ia+i)
     enddo

     phi=0.
     do i=0,nfft-1
        phi=phi + dphi
        c(i)=c(i) * cmplx(cos(phi),-sin(phi))
     enddo

     call four2a(c,nfft,1,-1,1)
     do i=0,nfft-1
        sx(i)=real(c(i))**2 + aimag(c(i))**2
        if(i.ge.1 .and. i.le.8) ssym(ig(i-1),k)=sx(i)
     enddo
  enddo

  sum=0.
  sig=0.
  do j=1,69
     smax=0.
     do i=0,7
        smax=max(smax,ssym(i,j))
        sum=sum+ssym(i,j)
     enddo
     sig=sig+smax
     sum=sum-smax
  enddo
  ave=sum/(69*7)
  call pctile(sx,nsps8,50,xmed)
  ssym=ssym/ave
  sig=sig/69.
  df8=1500.0/nsps8
  t=max(1.0,sig/xmed - 1.0)
  snrdb=db(t) - db(2500.0/df8) - 5.0
     
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
        i4=nint(10.0*(r1-r2))
        if(i4.lt.-127) i4=-127
        if(i4.gt.127) i4=127
        i4=i4+128
        i1SoftSymbolsScrambled(k)=i1
     enddo
  enddo

  call interleave9(i1SoftSymbolsScrambled,-1,i1SoftSymbols)
  call flush(81)
  call flush(82)

  return
end subroutine spec9
