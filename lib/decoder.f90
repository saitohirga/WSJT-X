subroutine decoder(ss,id2)

! Decoder for JT9.

  include 'constants.f90'
  real ss(184,NSMAX)
  character*22 msg
  character*20 datetime
  real*4 ccfred(NSMAX)
  real*4 red2(NSMAX)
  logical ccfok(NSMAX)
  logical done(NSMAX)
  logical done65
  integer*2 id2(NTMAX*12000)
  real*4 dd(NTMAX*12000)
  integer*1 i1SoftSymbols(207)
  common/npar/nutc,ndiskdat,ntrperiod,nfqso,newdat,npts8,nfa,nfb,ntol,  &
       kin,nzhsym,nsave,nagain,ndepth,ntxmode,nmode,datetime
  common/tracer/limtrace,lu
  save

  call system_clock(iclock0,iclock_rate,iclock_max)           !###
  nfreqs0=0
  nfreqs1=0
  ndecodes0=0
  ndecodes1=0

  open(13,file='decoded.txt',status='unknown')
  open(22,file='kvasd.dat',access='direct',recl=1024,status='unknown')

  npts65=52*12000
  ntol65=20
  done65=.false.
  if(nmode.ge.65 .and. ntxmode.eq.65) then
     if(newdat.ne.0) dd(1:npts65)=id2(1:npts65)
     call jt65a(dd,npts65,newdat,nutc,nfa,nfqso,ntol65,nagain,ndecoded)
     done65=.true.
  endif

  if(nmode.eq.65) go to 800

  nsynced=0
  ndecoded=0
  nsps=0

  nsps=6912                                   !Params for JT9-1
  df3=1500.0/2048.0

  tstep=0.5*nsps/12000.0                      !Half-symbol step (seconds)
  done=.false.

  nf0=0
  ia=max(1,nint((nfa-nf0)/df3))
  ib=min(NSMAX,nint((nfb-nf0)/df3))
  lag1=-(2.5/tstep + 0.9999)
  lag2=5.0/tstep + 0.9999
  if(newdat.ne.0) then
     call timer('sync9   ',0)
     call sync9(ss,nzhsym,lag1,lag2,ia,ib,ccfred,red2,ipk)
     call timer('sync9   ',1)
  endif

  nsps8=nsps/8
  df8=1500.0/nsps8
  dblim=db(864.0/nsps8) - 26.2

  do nqd=1,0,-1
     limit=1000
     ccflim=4.0
     red2lim=1.6
     schklim=2.2
     if(ndepth.eq.2) then
        limit=10000
        ccflim=3.5
     endif
     if(ndepth.ge.3) then
        limit=100000
        ccflim=2.5
     endif
     ccfok=.false.

     if(nqd.eq.1) then
        limit=100000
        nfa1=nfqso-ntol
        nfb1=nfqso+ntol
        ia=max(1,nint((nfa1-nf0)/df3))
        ib=min(NSMAX,nint((nfb1-nf0)/df3))
        ccfok(ia:ib)=.true.
        ia1=ia
        ib1=ib
     else
        nfa1=nfa
        nfb1=nfb
        ia=max(1,nint((nfa1-nf0)/df3))
        ib=min(NSMAX,nint((nfb1-nf0)/df3))
        do i=ia,ib
           ccfok(i)=ccfred(i).gt.ccflim .and. red2(i).gt.red2lim
        enddo
        ccfok(ia1:ib1)=.false.
     endif

     fgood=0.
     do i=ia,ib
        f=(i-1)*df3
        if(done(i) .or. (.not.ccfok(i)) .or.                               &
             (nqd.eq.0 .and. (ccfred(i).lt.ccflim-1.0))) cycle
        if(nqd.eq.1 .or.                                                   &
           (ccfred(i).ge.ccflim .and. abs(f-fgood).gt.10.0*df8)) then

           if(nqd.eq.0) nfreqs0=nfreqs0+1
           if(nqd.eq.1) nfreqs1=nfreqs1+1

           call timer('softsym ',0)
           fpk=nf0 + df3*(i-1)
           call softsym(id2,npts8,nsps8,newdat,fpk,syncpk,snrdb,xdt,    &
                freq,drift,schk,i1SoftSymbols)
           call timer('softsym ',1)

           if(schk.ge.schklim) then

              call timer('decode9 ',0)
              call decode9(i1SoftSymbols,limit,nlim,msg)
              call timer('decode9 ',1)

              sync=(syncpk+1)/4.0
              if(sync.lt.0.0 .or. snrdb.lt.dblim-2.0) sync=0.0
              nsync=sync
              if(nsync.gt.10) nsync=10
              nsnr=nint(snrdb)
              ndrift=nint(drift/df3)
              
              if(msg.ne.'                      ') then
                 if(nqd.eq.0) ndecodes0=ndecodes0+1
                 if(nqd.eq.1) ndecodes1=ndecodes1+1
                 
                 write(*,1000) nutc,nsnr,xdt,nint(freq),msg
1000             format(i4.4,i4,f5.1,i5,1x,'@',1x,a22)
                 write(13,1002) nutc,nsync,nsnr,xdt,freq,ndrift,msg
1002             format(i4.4,i4,i5,f6.1,f8.0,i4,3x,a22,' JT9')

                 iaa=max(1,i-1)
                 ibb=min(NSMAX,i+22)
                 fgood=f
                 nsynced=1
                 ndecoded=1
                 ccfok(iaa:ibb)=.false.
                 done(iaa:ibb)=.true.              
                 call flush(6)
              endif
           endif
        endif
     enddo
     call flush(6)
     if(nagain.ne.0) exit
  enddo

  if(nmode.ge.65 .and. (.not.done65)) then
     if(newdat.ne.0) dd(1:npts65)=id2(1:npts65)
     call jt65a(dd,npts65,newdat,nutc,nfa,nfqso,ntol65,nagain,ndecoded)
  endif

!### JT65 is not yet producing info for nsynced, ndecoded.
800 write(*,1010) nsynced,ndecoded
1010 format('<DecodeFinished>',2i4)
  call flush(6)
  close(13)
  close(22)

  return
end subroutine decoder
