subroutine jt4a(dd,jz,nutc,nfqso,ntol0,emedelay,dttol,nagain,ndepth,     &
     nclearave,minsync,minw,nsubmode,mycall,hiscall,hisgrid,nlist0,listutc0)

  use jt4
  use timer_module, only: timer

  integer listutc0(10)
  real*4 dd(jz)
  real*4 dat(30*12000)
  character*6 cfile6
  character*12 mycall,hiscall
  character*6 hisgrid

  mode4=nch(nsubmode+1)
  ntol=ntol0
  neme=0
  lumsg=6                         !### temp ? ###
  ndiag=1
  nlist=nlist0
  listutc=listutc0

! Lowpass filter and decimate by 2
  call timer('lpf1    ',0)
  call lpf1(dd,jz,dat,jz2)
  call timer('lpf1    ',1)

  i=index(MyCall,char(0))
  if(i.le.0) i=index(MyCall,' ')
  mycall=MyCall(1:i-1)//'            '
  i=index(HisCall,char(0))
  if(i.le.0) i=index(HisCall,' ')
  hiscall=HisCall(1:i-1)//'            '

  write(cfile6(1:4),1000) nutc
1000 format(i4.4)
  cfile6(5:6)='  '

  call timer('wsjt4   ',0)
  call wsjt4(dat,jz2,nutc,NClearAve,minsync,ntol,emedelay,dttol,mode4,minw, &
       mycall,hiscall,hisgrid,nfqso,NAgain,ndepth,neme)
  call timer('wsjt4   ',1)

  return
end subroutine jt4a
