subroutine genft8(msg37,mygrid,bcontest,i3,n3,isync,msgsent37,msgbits,itone)

! Encode an FT8 message, producing array itone().
  
  use crc
  use packjt
  include 'ft8_params.f90'
  character*22 msg,msgsent
  character*37 msg37,msgsent37
  character*6 mygrid
  character*87 cbits
  logical bcontest,checksumok
  integer*4 i4Msg6BitWords(12)                !72-bit message as 6-bit words
  integer*1 msgbits(KK),codeword(3*ND)
  integer*1 msgbits77(77)
  integer*1, target:: i1Msg8BitBytes(11)
  integer itone(NN)
  integer icos7(0:6)
  data icos7/2,5,6,0,4,1,3/                   !Costas 7x7 tone pattern

  if(isync.eq.2 ) goto 900
  
  msg=msg37(1:22)
  call packmsg(msg,i4Msg6BitWords,istdtype,bcontest) !Pack into 12 6-bit bytes
  call unpackmsg(i4Msg6BitWords,msgsent,bcontest,mygrid) !Unpack to get msgsent
  msgsent37(1:22)=msgsent
  msgsent37(23:37)='               '

  write(cbits,1000) i4Msg6BitWords,32*i3
1000 format(12b6.6,b8.8)
  read(cbits,1001) i1Msg8BitBytes(1:10)
1001 format(10b8)
  i1Msg8BitBytes(10)=iand(i1Msg8BitBytes(10),128+64+32)
  i1Msg8BitBytes(11)=0
  icrc12=crc12(c_loc(i1Msg8BitBytes),11)

  write(cbits,1003) i4Msg6BitWords,i3,icrc12
1003 format(12b6.6,b3.3,b12.12)
  read(cbits,1004) msgbits
1004 format(87i1)

  call encode174(msgbits,codeword)      !Encode the test message

! Message structure: S7 D29 S7 D29 S7
  itone(1:7)=icos7
  itone(36+1:36+7)=icos7
  itone(NN-6:NN)=icos7
  k=7
  do j=1,ND
     i=3*j -2
     k=k+1
     if(j.eq.30) k=k+7
     itone(k)=codeword(i)*4 + codeword(i+1)*2 + codeword(i+2)
  enddo
  return

900 continue

  call genft8_174_91(msg37,mygrid,bcontest,i3,n3,msgsent37,msgbits77,itone)

  return
end subroutine genft8
