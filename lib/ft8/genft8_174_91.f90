subroutine genft8_174_91(msg,mygrid,bcontest,i5bit,msgsent,msgbits,itone)

! Encode an FT8 message, producing array itone().
  
  use packjt
  include 'ft8_params.f90'
  character*22 msg,msgsent
  character*6 mygrid
  character*91 cbits
  logical bcontest
  integer*4 i4Msg6BitWords(12)                !72-bit message as 6-bit words
  integer*1 msgbits(77),codeword(174)
  integer itone(79)
  integer icos7(0:6)
  integer graymap(0:7)
  data icos7/3,1,4,0,6,5,2/                   !Costas 7x7 tone pattern
  data graymap/0,1,3,2,7,6,4,5/

  call packmsg(msg,i4Msg6BitWords,itype,bcontest) !Pack into 12 6-bit bytes
  call unpackmsg(i4Msg6BitWords,msgsent,bcontest,mygrid) !Unpack to get msgsent

  write(cbits,'(12b6.6,b8.8)') i4Msg6BitWords,8*i5bit
  read(cbits,'(77i1)') msgbits 
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
     indx=codeword(i)*4 + codeword(i+1)*2 + codeword(i+2)
     itone(k)=graymap(indx)
  enddo

  return
end subroutine genft8_174_91
