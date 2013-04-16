subroutine fillcom(nutc0,ndepth0)
  character*20 datetime
  common/npar/nutc,ndiskdat,ntrperiod,nfqso,newdat,npts8,nfa,nfb,ntol,  &
       kin,nzhsym,nsave,nagain,ndepth,nrxlog,nfsample,datetime
  save

  nutc=nutc0
  ndiskdat=1
  ntrperiod=60
  nfqso=1500
  newdat=1
  npts8=74736
  nfa=1000
  nfb=2000
  ntol=10
  kin=1024
  nzhsym=173
  nsave=0
  ndepth=ndepth0
  nrxlog=1
  nfsample=12000
  datetime="2013-Apr-16 15:13"
  
  return
end subroutine fillcom
