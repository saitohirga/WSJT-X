subroutine decjt9(ss,id2,nutc,nfqso,newdat,npts8,nfa,nfsplit,nfb,ntol,  &
     nzhsym,nagain,ndepth,nmode)

  include 'constants.f90'
  real ss(184,NSMAX)
  character*22 msg
  real*4 ccfred(NSMAX)
  real*4 red2(NSMAX)
  logical ccfok(NSMAX)
  logical done(NSMAX)
  integer*2 id2(NTMAX*12000)
  integer*1 i1SoftSymbols(207)
  common/decstats/num65,numbm,numkv,num9,numfano
  save ccfred,red2

  nsynced=0
  ndecoded=0
  nsps=6912                                   !Params for JT9-1
  df3=1500.0/2048.0

  tstep=0.5*nsps/12000.0                      !Half-symbol step (seconds)
  done=.false.

  nf0=0
  nf1=nfa
  if(nmode.eq.65+9) nf1=nfsplit
  ia=max(1,nint((nf1-nf0)/df3))
  ib=min(NSMAX,nint((nfb-nf0)/df3))
  lag1=-int(2.5/tstep + 0.9999)
  lag2=int(5.0/tstep + 0.9999)
  if(newdat.ne.0) then
     call timer('sync9   ',0)
     call sync9(ss,nzhsym,lag1,lag2,ia,ib,ccfred,red2,ipk)
     call timer('sync9   ',1)
  endif

  nsps8=nsps/8
  df8=1500.0/nsps8
  dblim=db(864.0/nsps8) - 26.2

  do nqd=1,0,-1
     limit=5000
     ccflim=3.0
     red2lim=1.6
     schklim=2.2
     if(ndepth.eq.2) then
        limit=10000
        ccflim=2.7
     endif
     if(ndepth.ge.3 .or. nqd.eq.1) then
        limit=30000
        ccflim=2.5
     endif
     if(nagain.ne.0) then
        limit=100000
        ccflim=2.4
     endif
     ccfok=.false.

     if(nqd.eq.1) then
        nfa1=nfqso-ntol
        nfb1=nfqso+ntol
        ia=max(1,nint((nfa1-nf0)/df3))
        ib=min(NSMAX,nint((nfb1-nf0)/df3))
        ccfok(ia:ib)=(ccfred(ia:ib).gt.(ccflim-2.0)) .and.               &
                     (red2(ia:ib).gt.(red2lim-1.0))
        ia1=ia
        ib1=ib
     else
        nfa1=nf1
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
        if(done(i) .or. (.not.ccfok(i))) cycle
        f=(i-1)*df3
        if(nqd.eq.1 .or.                                                   &
           (ccfred(i).ge.ccflim .and. abs(f-fgood).gt.10.0*df8)) then

           if(nqd.eq.0) nfreqs0=nfreqs0+1
           if(nqd.eq.1) nfreqs1=nfreqs1+1

           call timer('softsym ',0)
           fpk=nf0 + df3*(i-1)
           call softsym(id2,npts8,nsps8,newdat,fpk,syncpk,snrdb,xdt,    &
                freq,drift,schk,i1SoftSymbols)
           call timer('softsym ',1)

           sync=(syncpk+1)/4.0
           if(maxval(i1SoftSymbols).eq.0) cycle
           if(nqd.eq.1 .and. ((sync.lt.0.5) .or. (schk.lt.2.0))) cycle
           if(nqd.ne.1 .and. ((sync.lt.1.0) .or. (schk.lt.schklim))) cycle

           call timer('jt9fano ',0)
           call jt9fano(i1SoftSymbols,limit,nlim,msg)
           call timer('jt9fano ',1)

           if(sync.lt.0.0 .or. snrdb.lt.dblim-2.0) sync=0.0
           nsync=int(sync)
           if(nsync.gt.10) nsync=10
           nsnr=nint(snrdb)
           ndrift=nint(drift/df3)
           num9=num9+1

           if(msg.ne.'                      ') then
              numfano=numfano+1
              if(nqd.eq.0) ndecodes0=ndecodes0+1
              if(nqd.eq.1) ndecodes1=ndecodes1+1

              !$omp critical(decode_results) ! serialize writes - see also jt65a.f90
              write(*,1000) nutc,nsnr,xdt,nint(freq),msg
              write(13,1002) nutc,nsync,nsnr,xdt,freq,ndrift,msg
              call flush(6)
              call flush(13)
              !$omp end critical(decode_results)

1000          format(i4.4,i4,f5.1,i5,1x,'@',1x,a22)
1002          format(i4.4,i4,i5,f6.1,f8.0,i4,3x,a22,' JT9')

              iaa=max(1,i-1)
              ibb=min(NSMAX,i+22)
              fgood=f
              nsynced=1
              ndecoded=1
              ccfok(iaa:ibb)=.false.
              done(iaa:ibb)=.true.
           endif
        endif
     enddo
     if(nagain.ne.0) exit
  enddo

  return
end subroutine decjt9
