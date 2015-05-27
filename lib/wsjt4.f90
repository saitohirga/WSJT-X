subroutine wsjt4(dat,npts,nutc,NClearAve,minsync,ntol,emedelay,dttol,    &
     mode4,minw,mycall,hiscall,hisgrid,nfqso,NAgain,ndepth,neme)

! Orchestrates the process of decoding JT4 messages, using data that 
! have been 2x downsampled.

! NB: JT4 presently looks for only one decodable signal in the FTol 
! range -- analogous to the nqd=1 step in JT9 and JT65.

  use jt4
  real dat(npts)                                     !Raw data
  real z(458,65)
  logical first,prtavg
  character decoded*22,special*5
  character*22 avemsg,deepmsg,deepave,blank,deepmsg0,deepave1
  character csync*1,cqual*2
  character*12 mycall
  character*12 hiscall
  character*6 hisgrid
  data first/.true./,nutc0/-999/,nfreq0/-999999/
  save

  if(first) then
     nsave=0
     first=.false.
     blank='                      '
     ccfblue=0.
     ccfred=0.
     nagain=0
  endif

  zz=0.
  syncmin=5.0 + minsync
  naggressive=0
  if(ndepth.ge.2) naggressive=1
  nq1=3
  nq2=6
  if(naggressive.eq.1) nq1=1
  if(NClearAve.ne.0) then
     nsave=0
     iutc=-1
     nfsave=0.
     listutc=0
     ppsave=0.
     rsymbol=0.
     dtsave=0.
     syncsave=0.
  endif

! Attempt to synchronize: look for sync pattern, get DF and DT.
  call timer('sync4   ',0)
  call sync4(dat,npts,mode4,minw)
  call timer('sync4   ',1)

  call timer('zplt    ',0)
  do ich=4,6
     z(1:458,1:65)=zz(274:731,1:65,ich)
     call zplt(z,ich-4,syncz,dtxz,nfreqz,flipz,sync2z,0,emedelay,dttol,   &
          nfqso,ntol)
     if(ich.eq.5) then
        dtxzz=dtxz
        nfreqzz=nfreqz
     endif
  enddo
  call timer('zplt    ',1)

! Use results from zplt
  flip=flipz
  sync=syncz
  snrx=db(sync) - 26.
  nsnr=nint(snrx)
  if(sync.lt.syncmin) then
     write(*,1010) nutc,nsnr,dtxz,nfreqz
     go to 990
  endif

! We have achieved sync
  decoded=blank
  deepmsg=blank
  special='     '
  nsync=sync
  nsnrlim=-33
  csync='*'
  if(flip.lt.0.0) csync='#'
  qbest=0.
  qabest=0.
  prtavg=.false.

  do idt=-2,2
     dtx=dtxz + 0.03*idt
     nfreq=nfreqz + 2*idf


! Attempt a single-sequence decode, including deep4 if Fano fails.
     call timer('decode4 ',0)
     call decode4(dat,npts,dtx,nfreq,flip,mode4,ndepth,neme,minw,             &
          mycall,hiscall,hisgrid,decoded,nfano,deepmsg,qual,ich)
     call timer('decode4 ',1)

     if(nfano.gt.0) then
! Fano succeeded: display the message and return                      FANO OK
        write(*,1010) nutc,nsnr,dtx,nfreq,csync,decoded,' *',                 &
             char(ichar('A')+ich-1)
1010    format(i4.4,i4,f5.2,i5,1x,a1,1x,a22,a2,1x,a1,i3)
        nsave=0
        go to 990

     else          !                                                 NO FANO 
        if(qual.gt.qbest) then
           dtx0=dtx
           nfreq0=nfreq
           deepmsg0=deepmsg
           ich0=ich
           qbest=qual
        endif
     endif

! Single-sequence Fano decode failed, so try for an average Fano decode:
     qave=0.
! If this is a new minute or a new frequency, call avg4
     if(.not. prtavg) then
        if(nutc.ne.nutc0 .or. abs(nfreq-nfreq0).gt.ntol) then
           nutc0=nutc                                   !            TRY AVG
           nfreq0=nfreq
           nsave=nsave+1
           nsave=mod(nsave-1,64)+1
           call timer('avg4    ',0)
           call avg4(nutc,sync,dtx,flip,nfreq,mode4,ntol,ndepth,neme,       &
                mycall,hiscall,hisgrid,nfanoave,avemsg,qave,deepave,ich,    &
                ndeepave)
           call timer('avg4    ',1)
        endif

        if(nfanoave.gt.0) then
! Fano succeeded: display the message                           AVG FANO OK
           write(*,1010) nutc,nsnr,dtx,nfreq,csync,avemsg,' *',             &
                char(ichar('A')+ich-1),nfanoave
           prtavg=.true.
           cycle
        else
           if(qave.gt.qabest) then
              dtx1=dtx
              nfreq1=nfreq
              deepave1=deepave
              ich1=ich
              qabest=qave
           endif
        endif
     endif
  enddo

  dtx=dtx0
  nfreq=nfreq0
  deepmsg=deepmsg0
  ich=ich0
  qual=qbest
  if(int(qual).ge.nq1) then
     write(cqual,'(i2)') int(qual)
     write(*,1010) nutc,nsnr,dtx,nfreq,csync,         &
          deepmsg,cqual,char(ichar('A')+ich-1)
  else
     write(*,1010) nutc,nsnr,dtxz,nfreqz,csync
  endif

  dtx=dtx1
  nfreq=nfreq1
  deepave=deepave1
  ich=ich1
  qave=qabest
  if(int(qave).ge.nq1) then
     write(cqual,'(i2)') nint(qave)
     write(*,1010) nutc,nsnr,dtx,nfreq,csync,     &
          deepave,cqual,char(ichar('A')+ich-1),ndeepave
  endif

990  return
end subroutine wsjt4
