subroutine update_hasharray(recent_calls,nrecent,nhasharray)
  
  character*12 recent_calls(nrecent)
  character*22 hashmsg
  integer nhasharray(nrecent,nrecent)

  nhasharray=-1
  do i=1,nrecent
    do j=i+1,nrecent
      if( recent_calls(i) .ne. '  ' .and. recent_calls(j) .ne. '  ' ) then
        hashmsg=trim(recent_calls(i))//' '//trim(recent_calls(j))
        call fmtmsg(hashmsg,iz)
        call hash(hashmsg,22,ihash)
        ihash=iand(ihash,4095)
        nhasharray(i,j)=ihash
        hashmsg=trim(recent_calls(j))//' '//trim(recent_calls(i))
        call fmtmsg(hashmsg,iz)
        call hash(hashmsg,22,ihash)
        ihash=iand(ihash,4095)
        nhasharray(j,i)=ihash
      endif
    enddo
  enddo 

end subroutine update_hasharray
