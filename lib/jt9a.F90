subroutine jt9a

! These routines connect the shared memory region to the decoder.

  interface
     function address_jt9()
     integer*1, pointer :: address_jt9
     end function address_jt9
  end interface
  
  integer*1 attach_jt9,lock_jt9,unlock_jt9
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
     i=detach_jt9()
     go to 999
  endif
  
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

subroutine jt9c(ss,savg,c0,id2,nparams0)
  parameter (NTMAX=120)
  parameter (NSMAX=1365)
  integer*1 detach_jt9
  real*4 ss(184*NSMAX),savg(NSMAX)
  complex c0(NTMAX*1500)
  integer*2 id2(NTMAX*12000)

  integer nparams0(21),nparams(21)
  character*20 datetime
  common/npar/nutc,ndiskdat,ntrperiod,nfqso,newdat,npts8,nfa,nfb,ntol,  &
       kin,nzhsym,nsave,nagain,ndepth,nrxlog,nfsample,datetime
  equivalence (nparams,nutc)
  
  nparams=nparams0                     !Copy parameters into common/npar/

  call flush(6)
  if(sum(nparams).ne.0) call decoder(ss,c0,0)

  return
end subroutine jt9c
