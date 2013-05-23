subroutine jt9a

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
  logical fileExists
  common/tracer/limtrace,lu

  call getcwd(cwd)
  open(12,file='timer.out',status='unknown')

  limtrace=0
  lu=12
  i1=attach_jt9()

10 inquire(file=trim(cwd)//'/.lock',exist=fileExists)
  if(fileExists) then
     call sleep_msec(100)
     go to 10
  endif

  inquire(file=trim(cwd)//'/.quit',exist=fileExists)
  if(fileExists) then
!     call ftnquit
     i1=detach_jt9()
     go to 999
  endif
  if(i1.eq.999999) stop                  !Silence compiler warning
  
  nbytes=size_jt9()
  if(nbytes.le.0) then
     print*,'jt9a: Shared memory mem_jt9 does not exist.' 
     print*,"Must start 'jt9 -s' from within WSJT-X."
     go to 999
  endif
  p_jt9=>address_jt9()
  call jt9b(p_jt9,nbytes)

100 inquire(file=trim(cwd)//'/.lock',exist=fileExists)
  if(fileExists) go to 10
  call sleep_msec(100)
  go to 100

999 return
end subroutine jt9a

subroutine jt9b(jt9com,nbytes)
  parameter (NTMAX=120)
  parameter (NSMAX=1365)
  integer*1 jt9com(0:nbytes-1)
  kss=0
  ksavg=kss + 4*184*NSMAX
  kc0=ksavg + 4*NSMAX
  kid2=kc0 + 2*4*NTMAX*1500
  knutc=kid2 + 2*NTMAX*12000
  call jt9c(jt9com(kss),jt9com(ksavg),jt9com(kc0),jt9com(kid2),jt9com(knutc))
  return
end subroutine jt9b
