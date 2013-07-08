subroutine fillcom(nutc0,ndepth0)
  character*20 datetime
  common/npar/nutc,ndiskdat,ntrperiod,nfqso,newdat,npts8,nfa,nfb,ntol,  &
       kin,nzhsym,nsave,nagain,ndepth,ntxmode,nmode,datetime
  save

  nutc=nutc0
  ndiskdat=1
  ntrperiod=60
  nfqso=1197
  newdat=1
  npts8=74736
  nfa=2700
  nfb=4007
  ntol=3
  kin=1024
  nzhsym=173
  nsave=0
  ndepth=ndepth0
  ntxmode=9
  nmode=9+65
  datetime="2013-Apr-16 15:13"
  
  return
end subroutine fillcom
