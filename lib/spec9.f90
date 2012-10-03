subroutine spec9(c0,npts8,nsps,f0a,lagpk,fpk,i1SoftSymbols)

  parameter (MAXFFT=31500)
  complex c0(0:npts8-1)
  real s(0:MAXFFT-1)
  real ssym(0:8,85)
  complex c(0:MAXFFT-1)
  integer*1 i1SoftSymbolsScrambled(207)
  integer*1 i1SoftSymbols(207)
  integer isync(85)                !Sync vector
  data isync/                                    &
       1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,  &
       1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,0,0,0,1,0,  &
       0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,  &
       0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,  &
       1,0,0,0,1/
  integer ii(16)                       !Locations of sync symbols
  data ii/1,6,11,16,21,26,31,39,45,51,57,63,69,75,81,85/
  integer ig(0:7)
  data ig/0,1,3,2,7,6,4,5/             !Gray code removal
  save

  nsps8=nsps/8

  idt=-400
  idf=0.
  fshift=fpk-f0a + 0.1*idf
  twopi=8.0*atan(1.0)
  dphi=twopi*fshift/1500.0

  nfft=nsps8
  s=0.
!  istart=lagpk*nsps8 + idt
  istart=1520
  nsym=min((npts8-istart)/nsps8,85)

  do j=1,nsym
     ia=(j-1)*nsps8 + istart
     ib=ia+nsps8-1
     c(0:nfft-1)=c0(ia:ib)

     phi=0.
     do i=0,nfft-1
        phi=phi + dphi
        c(i)=c(i) * cmplx(cos(phi),-sin(phi))
     enddo

     call four2a(c,nfft,1,-1,1)
     do i=0,nfft-1
        sx=real(c(i))**2 + aimag(c(i))**2
        if(i.ge.1 .and. i.le.8) ssym(ig(i-1)+1,j)=sx
        s(i)=s(i) + sx
     enddo
  enddo

  m0=3
  ntones=8
  k=0
  do j=1,nsym
     if(isync(j).eq.1) cycle
     do m=m0-1,0,-1                   !Get bit-wise soft symbols
        n=2**m
        r1=0.
        r2=0.
        do i=0,ntones-1
           if(iand(i,n).ne.0) then
              r1=max(r1,ssym(i+1,j))
           else
              r2=max(r2,ssym(i+1,j))
           endif
        enddo
        k=k+1
        i1SoftSymbolsScrambled(k)=min(127,max(-127,nint(10.0*(r1-r2)))) + 128
     enddo
  enddo

  call interleave9(i1SoftSymbolsScrambled,-1,i1SoftSymbols)

  return
end subroutine spec9
