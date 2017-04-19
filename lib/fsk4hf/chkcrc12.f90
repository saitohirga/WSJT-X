subroutine chkcrc12(decoded,nbadcrc)

  use crc
  integer*1 decoded(84)
  integer*1, target:: i1Dec8BitBytes(11)

! Check the CRC
! Collapse 84 decoded bits to 11 bytes. Bytes 1-9 are the message,
! byte 10 and first half of byte 11 is the crc
  do ibyte=1,9
      itmp=0
    do ibit=1,8
      itmp=ishft(itmp,1)+iand(1,decoded((ibyte-1)*8+ibit))
    enddo
    i1Dec8BitBytes(ibyte)=itmp
  enddo

! Pack the crc into bytes 10 and 11 for crc12_check
  i1Dec8BitBytes(10)=decoded(73)*8 + decoded(74)*4 + decoded(75)*2 + decoded(76)
  i1Dec8BitBytes(11)=decoded(77)*128 + decoded(78)*64 +                      &
       decoded(79)*32 + decoded(80)*16 + decoded(81)*8 + decoded(82)*4 +   &
       decoded(83)*2 + decoded(84)
  nbadcrc=1
  if( crc12_check(c_loc (i1Dec8BitBytes), 11) ) nbadcrc=0
  
  return
end subroutine chkcrc12
