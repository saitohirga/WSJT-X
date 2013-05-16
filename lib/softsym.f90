subroutine softsym(c0,npts8,nsps8,newdat,fpk,syncpk,snrdb,xdt,freq,drift,   &
     schk,i1SoftSymbols)

! Compute the soft symbols

  complex c0(0:npts8-1)
  complex c2(0:4096-1)
  complex c3(0:4096-1)
  complex c5(0:4096-1)
  real a(3)
  integer*1 i1SoftSymbolsScrambled(207)
  integer*1 i1SoftSymbols(207)
  include 'jt9sync.f90'

  nspsd=16
  ndown=nsps8/nspsd

! Mix, low-pass filter, and downsample to 16 samples per symbol
  call downsam9(c0,npts8,nsps8,newdat,nspsd,fpk,c2,nz2)

  call peakdt9(c2,nz2,nsps8,nspsd,c3,nz3,xdt)  !Find DT

  fsample=1500.0/ndown
  a=0.
  call afc9(c3,nz3,fsample,a,syncpk)  !Find deltaF, fDot, fDDot
  freq=fpk - a(1)
  drift=-2.0*a(2)

  call twkfreq(c3,c5,nz3,fsample,a)   !Correct for deltaF, fDot, fDDot

! Compute soft symbols (in scrambled order)
  call symspec2(c5,nz3,nsps8,nspsd,fsample,freq,drift,snrdb,schk,      &
       i1SoftSymbolsScrambled)

! Remove interleaving
  call interleave9(i1SoftSymbolsScrambled,-1,i1SoftSymbols)

999 return
end subroutine softsym
