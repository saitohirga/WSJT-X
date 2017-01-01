subroutine extractmessage144(decoded,msgreceived,nhashflag,recent_calls,nrecent)
  use iso_c_binding, only: c_loc,c_size_t
  use packjt
  use hashing

  character*22 msgreceived
  character*12 call1,call2
  character*12 recent_calls(nrecent)
  integer*1 decoded(80)
  integer*1, target::  i1Dec8BitBytes(10)
  integer*1 i1hashdec
  integer*4 i4Dec6BitWords(12)

! Collapse 80 decoded bits to 10 bytes. Bytes 1-9 are the message, byte 10 is the hash
  do ibyte=1,10
      itmp=0
    do ibit=1,8
      itmp=ishft(itmp,1)+iand(1,decoded((ibyte-1)*8+ibit))
    enddo
    i1Dec8BitBytes(ibyte)=itmp
  enddo

! Calculate the hash using the first 9 bytes.
  ihashdec=nhash(c_loc(i1Dec8BitBytes),int(9,c_size_t),146)
  ihashdec=2*iand(ihashdec,255)

! Compare calculated hash with received byte 10 - if they agree, keep the message.
  i1hashdec=ihashdec
  if( i1hashdec .eq. i1Dec8BitBytes(10) ) then
! Good hash --- unpack 72-bit message
    do ibyte=1,12
      itmp=0
      do ibit=1,6
        itmp=ishft(itmp,1)+iand(1,decoded((ibyte-1)*6+ibit))
      enddo
      i4Dec6BitWords(ibyte)=itmp
    enddo
    call unpackmsg144(i4Dec6BitWords,msgreceived,call1,call2)
    nhashflag=1
    if( call1(1:2) .ne. 'CQ' .and. call1(1:2) .ne. '  ' ) then
      call update_recent_calls(call1,recent_calls,nrecent)
    endif
    if( call2(1:2) .ne. '  ' ) then
      call update_recent_calls(call2,recent_calls,nrecent)
    endif
  else
    msgreceived=' '
    nhashflag=-1
  endif 
  return
  end subroutine extractmessage144
