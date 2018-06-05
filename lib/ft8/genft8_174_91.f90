subroutine genft8_174_91(msg,mygrid,bcontest,i5bit,msgsent,msgbits,itone)

! Encode an FT8 message, producing array itone().
  
  use crc
  use packjt
  include 'ft8_params.f90'
  character*22 msg,msgsent
  character*6 mygrid
  character*91 cbits
  logical bcontest,checksumok
  integer*4 i4Msg6BitWords(12)                !72-bit message as 6-bit words
  integer*1 msgbits(91),codeword(174)
  integer*1, target:: i1Msg8BitBytes(12)
  integer itone(79)
  integer icos7(0:6)
#  data icos7/2,5,6,0,4,1,3/                   !Costas 7x7 tone pattern
  data icos7/3,1,4,0,6,5,2/                   !Costas 7x7 tone pattern

  call packmsg(msg,i4Msg6BitWords,itype,bcontest) !Pack into 12 6-bit bytes
  call unpackmsg(i4Msg6BitWords,msgsent,bcontest,mygrid) !Unpack to get msgsent

  write(cbits,1000) i4Msg6BitWords,8*i5bit
1000 format(12b6.6,b8.8)
  read(cbits,1001) i1Msg8BitBytes(1:10)
1001 format(10b8)
  i1Msg8BitBytes(10)=iand(i1Msg8BitBytes(10),128+64+32+16+8)
  i1Msg8BitBytes(11:12)=0
  icrc14=crc14(c_loc(i1Msg8BitBytes),12)
  i1Msg8BitBytes(11)=icrc14/256
  i1Msg8BitBytes(12)=iand (icrc14,255)

  write(cbits,1003) i4Msg6BitWords,i5bit,icrc14
1003 format(12b6.6,b5.5,b14.14)
  read(cbits,1004) msgbits
1004 format(91i1)

  call encode174_91(msgbits,codeword)      !Encode the test message

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
end subroutine genft8_174_91
