subroutine fast_decode(id2,narg,bShMsgs,line,pchk_file,mycall_12,hiscall_12)

  parameter (NMAX=30*12000)
  integer*2 id2(NMAX)
  integer narg(0:14)
  logical*1 bShMsgs
  real dat(30*12000)
  complex cdat(262145),cdat2(262145)
  real psavg(450)
  logical pick
  character*6 cfile6
  character*80 line(100)
  character*512 pchk_file
  character*12 mycall_12,hiscall_12
  character*6 mycall,hiscall
  save npts

  mycall=mycall_12(1:6)
  hiscall=hiscall_12(1:6)
  nutc=narg(0)
  ndat0=narg(1)
  nsubmode=narg(2)
  newdat=narg(3)
  minsync=narg(4)
  npick=narg(5)
  t0=0.001*narg(6)
  t1=0.001*narg(7)
  maxlines=narg(8)
  nmode=narg(9)
  nrxfreq=narg(10)
  ntol=narg(11)
  nhashcalls=narg(12)

  if(nmode.eq.102) then
     call fast9(id2,narg,line)
     go to 900
  else if(nmode.eq.103) then
     call jtmsk_decode(id2,narg,line)
     go to 900
  else if(nmode.eq.104) then
     call msk144_decode(id2,ndat0,nutc,0,pchk_file,mycall,hiscall,bShMsgs,  &
          ntol,line)
     go to 900
  endif

  if(newdat.eq.1) then
     cdat2=cdat
     ndat=ndat0
     call wav11(id2,ndat,dat)
     ndat=min(ndat,30*11025)
     call ana932(dat,ndat,cdat,npts)          !Make downsampled analytic signal
  endif

! Now cdat() is the downsampled analytic signal.  
! New sample rate = fsample = BW = 11025 * (9/32) = 3100.78125 Hz
! NB: npts, nsps, etc., are all reduced by 9/32

  write(cfile6,'(i6.6)') nutc
  nfreeze=1
  mousedf=0
  mousebutton=0
  mode4=1
  if(nsubmode.eq.1) mode4=2
  nafc=0
  ndebug=0
  t2=0.
  ia=1
  ib=npts
  pick=.false.

  if(npick.gt.0) then
     pick=.true.
     dt=1.0/11025.0 * (32.0/9.0)
     ia=t0/dt + 1.
     ib=t1/dt + 1.
     t2=t0
  endif
  jz=ib-ia+1
  line(1:100)(1:1)=char(0)
  if(npick.eq.2) then
     call iscat(cdat2(ia),jz,3,40,t2,pick,cfile6,minsync,ntol,NFreeze,    &
          MouseDF,mousebutton,mode4,nafc,ndebug,psavg,nmax,nlines,line)
  else
     call iscat(cdat(ia),jz,3,40,t2,pick,cfile6,minsync,ntol,NFreeze,     &
          MouseDF,mousebutton,mode4,nafc,ndebug,psavg,maxlines,nlines,line)
  endif

900 return
end subroutine fast_decode
