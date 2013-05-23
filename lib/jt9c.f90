subroutine jt9c(ss,savg,c0,id2,nparams0)

  parameter (NSMAX=22000)
  integer*1 detach_jt9
  real*4 ss(184*NSMAX),savg(NSMAX)
  complex c0(1800*1500)
  integer*2 id2(1800*12000)

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
