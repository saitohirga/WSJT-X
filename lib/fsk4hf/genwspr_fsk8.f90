subroutine genwspr_fsk8(msg,msgsent,itone)

! Encode a WSPR-LF 8-FSK message, producing array itone().
  
  use crc
  include 'wspr_fsk8_params.f90'

  character*22 msg,msgsent
  character*60 cbits
  integer*1,target :: idat(9)
  integer*1 msgbits(KK),codeword(3*ND)
  integer itone(NN)
  integer icos7(0:6)
  data icos7/2,5,6,0,4,1,3/                  !Costas 7x7 tone pattern

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

! Message structure: S7 D100 S7
  itone(1:7)=icos7
  itone(NN-6:NN)=icos7
  do j=1,ND
     i=3*j -2
     itone(j+7)=codeword(i)*4 + codeword(i+1)*2 + codeword(i+2)
  enddo

  return
end subroutine genwspr_fsk8
