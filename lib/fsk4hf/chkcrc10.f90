subroutine chkcrc10(decoded,nbadcrc)

  use crc
  integer*1 decoded(60)
  integer*1, target:: i1Dec8BitBytes(9)

! Check the CRC
  do ibyte=1,6
     itmp=0
     do ibit=1,8
        itmp=ishft(itmp,1)+iand(1,decoded((ibyte-1)*8+ibit))
     enddo
     i1Dec8BitBytes(ibyte)=itmp
  enddo
  i1Dec8BitBytes(7)=decoded(49)*128+decoded(50)*64

! Pack received CRC into bytes 8 and 9 for crc10_check
  i1Dec8BitBytes(8)=decoded(51)*2+decoded(52)
  i1Dec8BitBytes(9)=decoded(53)*128 + decoded(54)*64+decoded(55)*32 +   &
       decoded(56)*16
  i1Dec8BitBytes(9)=i1Dec8BitBytes(9) + decoded(57)*8+decoded(58)*4 +   &
       decoded(59)*2+decoded(60)*1
  nbadcrc=1
  if(crc10_check(c_loc(i1Dec8BitBytes),9)) nbadcrc=0

  return
end subroutine chkcrc10
