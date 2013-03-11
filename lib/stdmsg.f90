logical*1 function stdmsg(msg0)

  character*22 msg0,msg
  integer dat(12)
  logical text

  call packmsg(msg0,dat,text)
  call unpackmsg(dat,msg)
  stdmsg=msg.eq.msg0 .and. (.not.text)

  return
end function stdmsg
