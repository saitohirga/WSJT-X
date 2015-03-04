subroutine fillcom(nutc0,ndepth0,nrxfreq,mode,tx9,flow,fsplit,fhigh)
  character*20 datetime
  integer mode,flow,fsplit,fhigh
  logical tx9
  common/npar/nutc,ndiskdat,ntrperiod,nfqso,newdat,npts8,nfa,nfsplit,nfb,   &
       ntol,kin,nzhsym,nsave,nagain,ndepth,ntxmode,nmode,datetime
  save

  nutc=nutc0
  ndiskdat=1
  ntrperiod=60
  nfqso=nrxfreq
  newdat=1
  npts8=74736
  nfa=flow
  nfsplit=fsplit
  nfb=fhigh
  ntol=3
  kin=1024
  nzhsym=173
  nsave=0
  ndepth=ndepth0
  if (tx9) then
    ntxmode=9
  else
    ntxmode=65
  end if
  if (mode.lt.9) then
    nmode=65+9
  else
    nmode=mode
  end if
  datetime="2013-Apr-16 15:13"
  if(mode.eq.9 .and. nfsplit.ne.2700) nfa=nfsplit

  return
end subroutine fillcom
