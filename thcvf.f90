subroutine cs_init
  use dfmt
  type (RTL_CRITICAL_SECTION) ncrit1
  character*12 csub0
  integer*8 mtx
  common/mtxcom/mtx,ltrace,mtxstate,csub0
  ltrace=0
  mtx=loc(ncrit1)
  mtxstate=0
  csub0='**unlocked**'
  call InitializeCriticalSection(mtx)
  return
end subroutine cs_init

subroutine cs_destroy
  use dfmt
  type (RTL_CRITICAL_SECTION) ncrit1
  character*12 csub0
  integer*8 mtx
  common/mtxcom/mtx,ltrace,mtxstate,csub0
  call DeleteCriticalSection(mtx)
  return
end subroutine cs_destroy

subroutine th_create(sub)
  use dfmt
  external sub
  ith=CreateThread(0,0,sub,0,0,id)
  return
end subroutine th_create

subroutine th_exit
  use dfmt
  ncode=0
  call ExitThread(ncode)
  return
end subroutine th_exit

subroutine cs_lock(csub)
  use dfmt
  character*(*) csub
  character*12 csub0
  integer*8 mtx
  common/mtxcom/mtx,ltrace,mtxstate,csub0
  n=TryEnterCriticalSection(mtx)
  if(n.eq.0) then
! Another thread has already locked the mutex
     call EnterCriticalSection(mtx)
     iz=index(csub0,' ')
     if(ltrace.ge.1) print*,'"',csub,'" requested the mutex when "',  &
          csub0(:iz-1),'" owned it.'
  endif
  mtxstate=1
  csub0=csub
  if(ltrace.ge.3) print*,'Mutex locked by ',csub
  return
end subroutine cs_lock

subroutine cs_unlock
  use dfmt
  character*12 csub0
  integer*8 mtx
  common/mtxcom/mtx,ltrace,mtxstate,csub0
  mtxstate=0
  if(ltrace.ge.3) print*,'Mutex unlocked'
  call LeaveCriticalSection(mtx)
  return
end subroutine cs_unlock
