logical*1 function stdmsg(msg0)

  character*22 msg0,msg
  integer dat(12)

  call packmsg(msg0,dat,itype)
  call unpackmsg(dat,msg)
  stdmsg=(msg.eq.msg0) .and. (itype.ge.0)

  return
end function stdmsg
