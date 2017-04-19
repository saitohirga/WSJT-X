subroutine genmskhf(msgbits,id,icw,cbb,csync)

!Encode an MSK-HF message, produce baseband waveform and sync vector.

  parameter (KK=84)                     !Information bits (72 + CRC12)
  parameter (ND=168)                    !Data symbols: LDPC (168,84), r=1/2
  parameter (NS=65)                     !Sync symbols (2 x 26 + Barker 13)
  parameter (NR=3)                      !Ramp up/down
  parameter (NN=NR+NS+ND)               !Total symbols (236)
  parameter (NSPS=16)                   !Samples per MSK symbol (16)
  parameter (N2=2*NSPS)                 !Samples per OQPSK symbol (32)
  parameter (NZ=NSPS*NN)                !Samples in baseband waveform (3760)

  complex cbb(0:NZ-1)
  complex csync(0:NZ-1)
  real x(0:NZ-1)
  real y(0:NZ-1)
  real pp(N2)
  logical first
  integer*1 msgbits(KK),codeword(ND)
  integer icw(ND)
  integer id(NS+ND)
  integer isync(26)                          !Long sync vector
  integer ib13(13)                           !Barker 13 code
  data ib13/1,1,1,1,1,-1,-1,1,1,-1,1,-1,1/
  data first/.true./
  save first,isync,twopi,pp

  if(first) then
     n=z'2c1aeb1'
     do i=1,26
        isync(i)=-1
        if(iand(n,1).eq.1) isync(i)=1
        n=n/2
     enddo

     twopi=8.0*atan(1.0)
     do i=1,N2                             !Half-sine shaped pulse
        pp(i)=sin(0.5*(i-1)*twopi/N2)
     enddo
     first=.false.
  endif
    
  call random_number(x)
  codeword=0
  where(x(1:ND).ge.0.5) codeword=1
  call encode168(msgbits,codeword)      !Encode the test message
  icw=2*codeword - 1

! Message structure: R1 26*(S1+D1) S13 26*(D1+S1) R1
! Generate QPSK without any offset; then shift the y array to get OQPSK.

! Do the I channel first: results in array x
  n=0
  k=0
  ia=0
  ib=NSPS-1
  x(ia:ib)=0.                           !Ramp up (half-symbol; shape TBD)
  do j=1,26                             !Insert group of 26*(S1+D1)
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

  do j=1,26                             !Insert group of 26*(S1+D1)
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
  do j=1,116
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
  do j=1,26                            !Zero all data symbols in x
     ia=ib+1+N2
     ib=ia+N2-1
     x(ia:ib)=0.
     ia2=ib2+1+N2
     ib2=ia2+N2-1
     x(ia2:ib2)=0.
  enddo
  csync=x

  return
end subroutine genmskhf
