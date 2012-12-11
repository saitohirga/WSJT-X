program jt9code

! Generate simulated data for testing of WSJT-X

  parameter (NMAX=1800*12000)
  character msg*22,msg0*22,decoded*22

  integer*4 i4tone(85)             !Channel symbols (values 0-8)
  integer*4 i4data(69)
  integer*4 i4DataSymNoGray(69)    !Data Symbols, values 0-7
  integer*1 i1ScrambledBits(207)   !Unpacked bits, scrambled order
  integer*1 i1Bits(207)            !Encoded information-carrying bits
  integer*1 i1SoftSymbols(207)
  integer*1 i1
  equivalence (i1,i4)
  include 'jt9sync.f90'
  common/acom/dat(NMAX),iwave(NMAX)

  nargs=iargc()
  if(nargs.ne.1) then
     print*,'Usage: jt9code "message"'
     go to 999
  endif

  call getarg(1,msg0)
  write(*,1000) msg0
1000 format('Message:',3x,a22)
  msg=msg0
  ichk=0
  itext=0
  call genjt9(msg,ichk,decoded,i4tone,itext)       !Encode message into tone #s
  write(*,1002) i4tone
1002 format('Channel symbols:'/(30i2))
  if(itext.eq.0) write(*,1004) decoded
1004 format('Decoded message:',1x,a22)
  if(itext.ne.0) write(*,1005) decoded
1005 format('Decoded message:',1x,a22,3x,'(free text)')

999 end program jt9code
