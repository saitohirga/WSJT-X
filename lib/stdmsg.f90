function stdmsg(msg0,bcontest,mygrid)

  use iso_c_binding, only: c_bool
  use packjt
  character*22 msg0,msg1,msg
  character*6 mygrid
  integer dat(12)
  logical(c_bool), value :: bcontest
  logical(c_bool) :: stdmsg

  msg1=msg0
  i0=index(msg1,' OOO ')
  if(i0.gt.10) msg1=msg0(1:i0)
  call packmsg(msg0,dat,itype,logical(bcontest))
  call unpackmsg(dat,msg,logical(bcontest),mygrid)
  stdmsg=(msg.eq.msg1) .and. (itype.ge.0) .and. itype.ne.6

  return
end function stdmsg
