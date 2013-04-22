subroutine decode9a(c0,npts8,nsps8,fpk,syncpk,snrdb,xdt,freq,drift,   &
     i1SoftSymbols)

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

! Downsample to 16 samples/symbol
  call downsam9(c0,npts8,nsps8,nspsd,fpk,c2,nz2)

  call peakdt9(c2,nz2,nsps8,nspsd,c3,nz3,xdt)

  fsample=1500.0/ndown
  a=0.
  call afc9(c3,nz3,fsample,a,syncpk)

  call twkfreq(c3,c5,nz3,fsample,a)

  call symspec2(c5,nz3,nsps8,nspsd,fsample,snrdb,i1SoftSymbolsScrambled)

  call interleave9(i1SoftSymbolsScrambled,-1,i1SoftSymbols)
  
  freq=fpk - a(1)
  drift=-2.0*a(2)

  return
end subroutine decode9a
