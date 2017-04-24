subroutine genwsprlf(msgbits,id,icw,cbb,csync)

!Encode a WSPR-LF message, produce baseband waveform and sync vector.

  parameter (KK=60)                     !Information bits (50 + CRC10)
  parameter (ND=300)                    !Data symbols: LDPC (300,60), r=1/5
  parameter (NS=109)                    !Sync symbols (2 x 48 + Barker 13)
  parameter (NR=3)                      !Ramp up/down (2 x half-length symbols)
  parameter (NN=NR+NS+ND)               !Total symbols (410)
  parameter (NSPS=16)                   !Samples per MSK symbol (16)
  parameter (N2=2*NSPS)                 !Samples per OQPSK symbol (32)
  parameter (N13=13*N2)                 !Samples in central sync vector (416)
  parameter (NZ=NSPS*NN)                !Samples in baseband waveform (6560)
  parameter (NFFT1=4*NSPS,NH1=NFFT1/2)

  complex cbb(0:NZ-1)
  complex csync(0:NZ-1)
  real x(0:NZ-1)
  real y(0:NZ-1)
  real pp(N2)
  logical first
  integer*1 msgbits(KK),codeword(ND)
  integer icw(ND)
  integer id(NS+ND)
  integer isync(48)                          !Long sync vector
  integer ib13(13)                           !Barker 13 code
  integer*8 n8
  data ib13/1,1,1,1,1,-1,-1,1,1,-1,1,-1,1/
  data first/.true./
  save first,isync,twopi,pp

  if(first) then
     n8=z'cbf089223a51'
     do i=1,48
        isync(i)=-1
        if(iand(n8,1).eq.1) isync(i)=1
        n8=n8/2
     enddo

     twopi=8.0*atan(1.0)
     do i=1,N2                             !Half-sine shaped pulse
        pp(i)=sin(0.5*(i-1)*twopi/N2)
     enddo
     first=.false.
  endif

  call encode300(msgbits,codeword)      !Encode the test message
  icw=2*codeword - 1

! Message structure: R1 48*(S1+D1) S13 48*(D1+S1) R1
! Generate QPSK without any offset; then shift the y array to get OQPSK.

! Do the I channel first: results in array x
  n=0
  k=0
  ia=0
  ib=NSPS-1
  x(ia:ib)=0.                           !Ramp up (half-symbol; shape TBD)
  do j=1,48                             !Insert group of 48*(S1+D1)
     ia=ib+1
     ib=ia+N2-1
     n=n+1
     id(n)=2*isync(j)
     x(ia:ib)=isync(j)*pp               !Insert Sync bit
     ia=ib+1
     ib=ia+N2-1
     k=k+1
     n=n+1
     id(n)=icw(k)
     x(ia:ib)=id(n)*pp                  !Insert data bit
  enddo

  do j=1,13                             !Insert Barker 13 code
     ia=ib+1
     ib=ia+N2-1
     n=n+1
     id(n)=2*ib13(j)
     x(ia:ib)=ib13(j)*pp
  enddo

  do j=1,48                             !Insert group of 48*(S1+D1)
     ia=ib+1
     ib=ia+N2-1
     k=k+1
     n=n+1
     id(n)=icw(k)
     x(ia:ib)=id(n)*pp                  !Insert data bit
     ia=ib+1
     ib=ia+N2-1
     n=n+1
     id(n)=2*isync(j)
     x(ia:ib)=isync(j)*pp               !Insert Sync bit
  enddo
  ia=ib+1
  ib=ia+NSPS-1
  x(ia:ib)=0.                           !Ramp down (half-symbol; shape TBD)

! Now do the Q channel: results in array y
  ia=0
  ib=NSPS-1
  y(ia:ib)=0.                           !Ramp up  (half-symbol; shape TBD)
  do j=1,204
     ia=ib+1
     ib=ia+N2-1
     k=k+1
     n=n+1
     id(n)=icw(k)
     y(ia:ib)=id(n)*pp
  enddo
  ia=ib+1
  ib=ia+NSPS-1
  y(ia:ib)=0.                          !Ramp down (half-symbol; shape TBD)
  y=cshift(y,-NSPS)                    !Shift Q array to get OQPSK
  cbb=cmplx(x,y)                       !Complex baseband waveform

  ib=NSPS-1
  ib2=NSPS-1+64*N2 
  do j=1,48                            !Zero all data symbols in x
     ia=ib+1+N2
     ib=ia+N2-1
     x(ia:ib)=0.
     ia2=ib2+1+N2
     ib2=ia2+N2-1
     x(ia2:ib2)=0.
  enddo
  csync=x

  return
end subroutine genwsprlf
