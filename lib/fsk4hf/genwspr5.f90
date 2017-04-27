subroutine genwspr5(msg,ichk,msgsent,itone,itype)

!Encode a WSPR-LF message, produce itone() array.
  
  use crc
  include 'wsprlf_params.f90'

  character*22 msg,msgsent
  character*60 cbits
  integer*1,target :: idat(9)
  integer*1 msgbits(KK),codeword(ND)
  logical first
  integer icw(ND)
  integer id(NS+ND)
  integer jd(NS+ND)
  integer isync(48)                          !Long sync vector
  integer ib13(13)                           !Barker 13 code
  integer itone(NN)
  integer*8 n8
  data ib13/1,1,1,1,1,-1,-1,1,1,-1,1,-1,1/
  data first/.true./
  save first,isync

  if(first) then
     n8=z'cbf089223a51'
     do i=1,48
        isync(i)=-1
        if(iand(n8,1).eq.1) isync(i)=1
        n8=n8/2
     enddo
     first=.false.
  endif

  idat=0
  call wqencode(msg,ntype0,idat)             !Source encoding
  id7=idat(7)
  if(id7.lt.0) id7=id7+256
  id7=id7/64
  icrc=crc10(c_loc(idat),9)                  !Compute the 10-bit CRC
  idat(8)=icrc/256                           !Insert CRC into idat(8:9)
  idat(9)=iand(icrc,255)
  call wqdecode(idat,msgsent,itype)

  write(cbits,1004) idat(1:6),id7,icrc
1004 format(6b8.8,b2.2,b10.10)
  read(cbits,1006) msgbits
1006 format(60i1)

!  call chkcrc10(msgbits,nbadcrc)
!  print*,msgsent,itype,crc10_check(c_loc(idat),9),nbadcrc
  
  call encode300(msgbits,codeword)      !Encode the test message
  icw=2*codeword - 1                    !NRZ codeword

! Message structure:
! I channel:  R1 48*(S1+D1) S13 48*(D1+S1) R1
! Q channel:  R1 D109 R1
! Generate QPSK with no offset, then shift the y array to get OQPSK.

! I channel:
  n=0
  k=0
  do j=1,48                             !Insert group of 48*(S1+D1)
     n=n+1
     id(n)=2*isync(j)
     k=k+1
     n=n+1
     id(n)=icw(k)
  enddo

  do j=1,13                             !Insert Barker 13 code
     n=n+1
     id(n)=2*ib13(j)
  enddo

  do j=1,48                             !Insert group of 48*(S1+D1)
     k=k+1
     n=n+1
     id(n)=icw(k)
     n=n+1
     id(n)=2*isync(j)
  enddo

! Q channel
  do j=1,204
     k=k+1
     n=n+1
     id(n)=icw(k)
  enddo

! Map I and Q to tones.
  n=0
  jz=(NS+ND+1)/2
  do j=1,jz-1
     jd(2*j-1)=id(j)/abs(id(j))
     jd(2*j)=id(j+jz)/abs(id(j+jz))
  enddo
  jd(NS+ND)=id(jz)/abs(id(jz))
  itone=0 
  do j=1,jz-1
     itone(2*j-1)=(jd(2*j)*jd(2*j-1)+1)/2;
     itone(2*j)=-(jd(2*j)*jd(2*j+1)-1)/2;
  enddo
  itone(NS+ND)=jd(NS+ND)                       !### Is this correct ??? ###

  return
end subroutine genwspr5
