subroutine extractmessage174(decoded,msgreceived,ncrcflag,recent_calls,nrecent)
  use iso_c_binding, only: c_loc,c_size_t
  use crc
  use packjt

  character*22 msgreceived
  character*12 call1,call2
  character*12 recent_calls(nrecent)
  character*87 cbits
  integer*1 decoded(87)
  integer*1, target::  i1Dec8BitBytes(11)
  integer*4 i4Dec6BitWords(12)

! Write decoded bits into cbits: 75-bit message plus 12-bit CRC
  write(cbits,1000) decoded
1000 format(87i1)
  read(cbits,1001) i1Dec8BitBytes
1001 format(11b8)
  read(cbits,1002) ncrc12                         !Received CRC12
1002 format(75x,b12)

  i1Dec8BitBytes(10)=iand(i1Dec8BitBytes(10),128+64+32)
  i1Dec8BitBytes(11)=0
  icrc12=crc12(c_loc(i1Dec8BitBytes),11)          !CRC12 computed from 75 msg bits

  if(ncrc12.eq.icrc12) then
! CRC12 checks out --- unpack 72-bit message
    do ibyte=1,12
      itmp=0
      do ibit=1,6
        itmp=ishft(itmp,1)+iand(1,decoded((ibyte-1)*6+ibit))
      enddo
      i4Dec6BitWords(ibyte)=itmp
    enddo
    call unpackmsg144(i4Dec6BitWords,msgreceived,call1,call2)
    ncrcflag=1
    if( call1(1:2) .ne. 'CQ' .and. call1(1:2) .ne. '  ' ) then
      call update_recent_calls(call1,recent_calls,nrecent)
    endif
    if( call2(1:2) .ne. '  ' ) then
      call update_recent_calls(call2,recent_calls,nrecent)
    endif
  else
    msgreceived=' '
    ncrcflag=-1
  endif 
  return
  end subroutine extractmessage174
