subroutine jt9c(ss,savg,id2,nparams0)

  include 'constants.f90'
  real*4 ss(184*NSMAX),savg(NSMAX)
  integer*2 id2(NTMAX*12000)

  integer nparams0(46),nparams(46)
  character datetime*20,mycall*12,mygrid*6,hiscall*12,hisgrid*6
  common/npar/nutc,ndiskdat,ntrperiod,nfqso,newdat,npts8,nfa,nfsplit,nfb,   &
       ntol,kin,nzhsym,nsave,nagain,ndepth,ntxmode,nmode,minw,nclearave,    &
       emedelay,dttol,nlist,listutc(10),datetime,mycall,mygrid,hiscall,hisgrid

  common/patience/npatience,nthreads
  equivalence (nparams,nutc)

  nutc=id2(1)+int(savg(1))             !Silence compiler warning
  nparams=nparams0                     !Copy parameters into common/npar/
!  if(ndiskdat.ne.0) npatience=2

  call flush(6)
  nfsample=12000
  call decoder(ss,id2,nfsample)

  return
end subroutine jt9c
