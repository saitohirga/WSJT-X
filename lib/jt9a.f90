subroutine jt9a(thekey,ldir)

  character(len=*), intent(in):: thekey
  character(len=*), intent(in):: ldir

! These routines connect the shared memory region to the decoder.
  interface
     function address_jt9()
     integer*1, pointer :: address_jt9
     end function address_jt9
  end interface
  
  integer*1 attach_jt9
!  integer*1 lock_jt9,unlock_jt9
  integer size_jt9
  integer*1, pointer :: p_jt9
  character*80 cwd
! Multiple instances:
  character*80 mykey
  logical fileExists
  common/tracer/limtrace,lu

! Multiple instances:
  i0 = len(trim(thekey))

  call getcwd(cwd)
  open(12,file='timer.out',status='unknown')

  limtrace=0
!  limtrace=-1                            !Disable all calls to timer()
  lu=12

! Multiple instances: set the shared memory key before attaching
  mykey=trim(repeat(thekey,1))
  i0 = len(mykey)
  i0=setkey_jt9(trim(mykey))

  i1=attach_jt9()

10 inquire(file=trim(ldir)//'/.lock',exist=fileExists)
  if(fileExists) then
     call sleep_msec(100)
     go to 10
  endif

  inquire(file=trim(ldir)//'/.quit',exist=fileExists)
  if(fileExists) then
!     call ftnquit
     i1=detach_jt9()
     go to 999
  endif
  if(i1.eq.999999) stop                  !Silence compiler warning
  
  nbytes=size_jt9()
  if(nbytes.le.0) then
     print*,'jt9a: Shared memory mem_jt9 does not exist.' 
     print*,"Must start 'jt9 -s <thekey>' from within WSJT-X."
     go to 999
  endif
  p_jt9=>address_jt9()
  call timer('jt9b    ',0)
  call jt9b(p_jt9,nbytes)
  call timer('jt9b    ',1)

100 inquire(file=trim(ldir)//'/.lock',exist=fileExists)
  if(fileExists) go to 10
  call sleep_msec(100)
  go to 100

999 call timer('jt9b    ',101)

  return
end subroutine jt9a
