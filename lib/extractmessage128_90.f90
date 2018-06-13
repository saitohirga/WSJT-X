subroutine extractmessage128_90(decoded,msgreceived,ncrcflag)
  use iso_c_binding, only: c_loc,c_size_t
  use crc
  use packjt

  character*22 msgreceived
  character*90 cbits
  integer*1 decoded(90)
  integer*1, target::  i1Dec8BitBytes(12)
  integer*4 i4Dec6BitWords(12)

! Write decoded bits into cbits: 77-bit message plus 13-bit CRC
  write(cbits,1000) decoded
1000 format(90i1)
  read(cbits,1001) i1Dec8BitBytes
1001 format(12b8)
  read(cbits,1002) ncrc13                         !Received CRC12
1002 format(77x,b13)

  i1Dec8BitBytes(10)=iand(i1Dec8BitBytes(10),128+64+32+16+8)
  i1Dec8BitBytes(11:12)=0
  icrc13=crc13(c_loc(i1Dec8BitBytes),12)          !CRC13 computed from 77 msg bits

  if(ncrc13.eq.icrc13 .or. sum(decoded(57:87)).eq.0) then  !### Kludge ###  ???
! CRC13 checks out --- unpack 72-bit message
    read(cbits,'(12b6)') i4Dec6BitWords 
    call unpackmsg(i4Dec6BitWords,msgreceived,.false.,'      ')
    ncrcflag=1
  else
    msgreceived=' '
    ncrcflag=-1
  endif 
  return
  end subroutine extractmessage128_90
