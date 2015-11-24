subroutine fillcom(nutc0,ndepth0,nrxfreq,mode,tx9,flow,fsplit,fhigh)
  integer mode,flow,fsplit,fhigh
  logical tx9

  character datetime*20,mycall*12,mygrid*6,hiscall*12,hisgrid*6
  common/npar/nutc,ndiskdat,ntrperiod,nfqso,newdat,npts8,nfa,nfsplit,nfb,    &
       ntol,kin,nzhsym,nsubmode,nagain,ndepth,ntxmode,nmode,minw,nclearave,  &
       minsync,emedelay,dttol,nlist,listutc(10),n2pass,nranera,naggressive,  &
       nrobust,nspare(10),datetime,mycall,mygrid,hiscall,hisgrid
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
  ntol=20
  kin=648000
  nzhsym=181
  ndepth=ndepth0
  dttol=3.0
  if (tx9) then
    ntxmode=9
  else
    ntxmode=65
  end if
  if (mode.eq.0) then
    nmode=65+9
  else
    nmode=mode
  end if
  datetime="2013-Apr-16 15:13"                        !### Temp
  if(mode.eq.9 .and. nfsplit.ne.2700) nfa=nfsplit

  return
end subroutine fillcom
