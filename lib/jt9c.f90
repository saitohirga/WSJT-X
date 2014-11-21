subroutine jt9c(ss,savg,id2,nparams0)

  include 'constants.f90'
  real*4 ss(184*NSMAX),savg(NSMAX)
  integer*2 id2(NTMAX*12000)

  integer nparams0(22),nparams(22)
  character*20 datetime
  common/npar/nutc,ndiskdat,ntrperiod,nfqso,newdat,npts8,nfa,nfsplit,nfb,   &
       ntol,kin,nzhsym,nsave,nagain,ndepth,ntxmode,nmode,datetime
  common/patience/npatience
  equivalence (nparams,nutc)

  nutc=id2(1)+int(savg(1))             !Silence compiler warning
  nparams=nparams0                     !Copy parameters into common/npar/
  if(ndiskdat.ne.0) npatience=2

  call flush(6)
!  if(sum(nparams).ne.0) call decoder(ss,id2,ldir)
  call decoder(ss,id2)

  return
end subroutine jt9c
