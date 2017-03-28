subroutine extractmessage168(decoded,msgreceived,ncrcflag,recent_calls,nrecent)
  use iso_c_binding, only: c_loc,c_size_t
  use crc
  use packjt

  character*22 msgreceived
  character*12 call1,call2
  character*12 recent_calls(nrecent)
  integer*1 decoded(84)
  integer*1, target::  i1Dec8BitBytes(11)
  integer*4 i4Dec6BitWords(12)

! Collapse 84 decoded bits to 11 bytes. Bytes 1-9 are the message, byte 10 and first half of byte 11 is the crc
  do ibyte=1,9
      itmp=0
    do ibit=1,8
      itmp=ishft(itmp,1)+iand(1,decoded((ibyte-1)*8+ibit))
    enddo
    i1Dec8BitBytes(ibyte)=itmp
  enddo
! Need to pack the crc into bytes 10 and 11 for crc12_check
  i1Dec8BitBytes(10)=decoded(73)*8+decoded(74)*4+decoded(75)*2+decoded(76)
  i1Dec8BitBytes(11)=decoded(77)*128+decoded(78)*64+decoded(79)*2*32+decoded(80)*16
  i1Dec8BitBytes(11)=i1Dec8BitBytes(11)+decoded(81)*8+decoded(82)*4+decoded(83)*2+decoded(84)

  if( crc12_check(c_loc (i1Dec8BitBytes), 11) ) then
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
  end subroutine extractmessage168
