module jt4_decode
  type :: jt4_decoder
     procedure(jt4_decode_callback), pointer :: decode_callback => null ()
     procedure(jt4_average_callback), pointer :: average_callback => null ()
   contains
     procedure :: decode
     procedure, private :: wsjt4, avg4
  end type jt4_decoder

  !
  ! Callback function to be called with each decode
  !
  abstract interface
     subroutine jt4_decode_callback (this, utc, snr, dt, freq, have_sync,     &
          sync, is_deep, decoded, qual, ich, is_average, ave)
       import jt4_decoder
       implicit none
       class(jt4_decoder), intent(inout) :: this
       integer, intent(in) :: utc
       integer, intent(in) :: snr
       real, intent(in) :: dt
       integer, intent(in) :: freq
       logical, intent(in) :: have_sync
       logical, intent(in) :: is_deep
       character(len=1), intent(in) :: sync
       character(len=22), intent(in) :: decoded
       real, intent(in) :: qual
       integer, intent(in) :: ich
       logical, intent(in) :: is_average
       integer, intent(in) :: ave
     end subroutine jt4_decode_callback
  end interface

  !
  ! Callback function to be called with each average result
  !
  abstract interface
     subroutine jt4_average_callback (this, used, utc, sync, dt, freq, flip)
       import jt4_decoder
       implicit none
       class(jt4_decoder), intent(inout) :: this
       logical, intent(in) :: used
       integer, intent(in) :: utc
       real, intent(in) :: sync
       real, intent(in) :: dt
       integer, intent(in) :: freq
       logical, intent(in) :: flip
     end subroutine jt4_average_callback
  end interface

contains

  subroutine decode(this,decode_callback,dd,jz,nutc,nfqso,ntol0,emedelay,     &
       dttol,nagain,ndepth,nclearave,minsync,minw,nsubmode,mycall,hiscall,    &
       hisgrid,nlist0,listutc0,average_callback)

    use jt4
    use timer_module, only: timer

    class(jt4_decoder), intent(inout) :: this
    procedure(jt4_decode_callback) :: decode_callback
    integer, intent(in) :: jz,nutc,nfqso,ntol0,ndepth,nclearave,              &
         minsync,minw,nsubmode,nlist0,listutc0(10)
    real, intent(in) :: dd(jz),emedelay,dttol
    logical, intent(in) :: nagain
    character(len=12), intent(in) :: mycall,hiscall
    character(len=6), intent(in) :: hisgrid
    procedure(jt4_average_callback), optional :: average_callback

    real*4 dat(30*12000)
    character*6 cfile6

    this%decode_callback => decode_callback
    if (present (average_callback)) then
       this%average_callback => average_callback
    end if
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

    !i=index(MyCall,char(0))
    !if(i.le.0) i=index(MyCall,' ')
    !mycall=MyCall(1:i-1)//'            '
    !i=index(HisCall,char(0))
    !if(i.le.0) i=index(HisCall,' ')
    !hiscall=HisCall(1:i-1)//'            '

    write(cfile6(1:4),1000) nutc
1000 format(i4.4)
    cfile6(5:6)='  '

    call timer('wsjt4   ',0)
    call this%wsjt4(dat,jz2,nutc,NClearAve,minsync,ntol,emedelay,dttol,mode4, &
         minw,mycall,hiscall,hisgrid,nfqso,NAgain,ndepth,neme)
    call timer('wsjt4   ',1)

    return
  end subroutine decode

  subroutine wsjt4(this,dat,npts,nutc,NClearAve,minsync,ntol,emedelay,dttol,  &
       mode4,minw,mycall,hiscall,hisgrid,nfqso,NAgain,ndepth,neme)

    ! Orchestrates the process of decoding JT4 messages, using data that 
    ! have been 2x downsampled.

    ! NB: JT4 presently looks for only one decodable signal in the FTol 
    ! range -- analogous to the nqd=1 step in JT9 and JT65.

    use jt4
    use timer_module, only: timer

    class(jt4_decoder), intent(inout) :: this
    integer, intent(in) :: npts,nutc,NClearAve,minsync,ntol,mode4,minw,       &
         nfqso,ndepth,neme
    logical, intent(in) :: NAgain
    character(len=12), intent(in) :: mycall,hiscall
    character(len=6), intent(in) :: hisgrid

    real, intent(in) :: dat(npts) !Raw data
    real z(458,65)
    logical first,prtavg
    character decoded*22,special*5
    character*22 avemsg,deepmsg,deepave,blank,deepmsg0,deepave1
    character csync*1
    data first/.true./,nutc0/-999/,nfreq0/-999999/
    save

    if(first) then
       nsave=0
       first=.false.
       blank='                      '
       ccfblue=0.
       ccfred=0.
       !nagain=.false.
    endif

    zz=0.
    syncmin=3.0 + minsync
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
       nfanoave=0
       ndeepave=0
    endif

    ! Attempt to synchronize: look for sync pattern, get DF and DT.
    call timer('sync4   ',0)
    call sync4(dat,npts,mode4,minw)
    call timer('sync4   ',1)

    call timer('zplt    ',0)
    do ich=4,7
       z(1:458,1:65)=zz(274:731,1:65,ich)
       call zplt(z,ich-4,syncz,dtxz,nfreqz,flipz,sync2z,0,emedelay,dttol,     &
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
       if (associated (this%decode_callback)) then
          call this%decode_callback(nutc,nsnr,dtxz,nfreqz,.false.,csync,      &
               .false.,decoded,0.,ich,.false.,0)
       end if
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
       call decode4(dat,npts,dtx,nfreq,flip,mode4,ndepth,neme,minw,           &
            mycall,hiscall,hisgrid,decoded,nfano,deepmsg,qual,ich)
       call timer('decode4 ',1)

       if(nfano.gt.0) then
          ! Fano succeeded: report the message and return               FANO OK
          if (associated (this%decode_callback)) then
             call this%decode_callback(nutc,nsnr,dtx,nfreq,.true.,csync,      &
                  .false.,decoded,0.,ich,.false.,0)
          end if
          nsave=0
          go to 990

       else          !                                                  NO FANO 
          if(qual.gt.qbest) then
             dtx0=dtx
             nfreq0=nfreq
             deepmsg0=deepmsg
             ich0=ich
             qbest=qual
          endif
       endif

       if(idt.ne.0) cycle
       ! Single-sequence Fano decode failed, so try for an average Fano decode:
       qave=0.
       ! If this is a new minute or a new frequency, call avg4
       if(.not. prtavg) then
          if(nutc.ne.nutc0 .or. abs(nfreq-nfreq0).gt.ntol) then
             nutc0=nutc                                   !             TRY AVG
             nfreq0=nfreq
             nsave=nsave+1
             nsave=mod(nsave-1,64)+1
             call timer('avg4    ',0)
             call this%avg4(nutc,sync,dtx,flip,nfreq,mode4,ntol,ndepth,neme,  &
                  mycall,hiscall,hisgrid,nfanoave,avemsg,qave,deepave,ich,    &
                  ndeepave)
             call timer('avg4    ',1)
          endif

          if(nfanoave.gt.0) then
             ! Fano succeeded: report the mess                      AVG FANO OK
             if (associated (this%decode_callback)) then
                call this%decode_callback(nutc,nsnr,dtx,nfreq,.true.,csync,   &
                     .false.,avemsg,0.,ich,.true.,nfanoave)
             end if
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
    if (associated (this%decode_callback)) then
       if(int(qual).ge.nq1) then
          call this%decode_callback(nutc,nsnr,dtx,nfreqz,.true.,csync,.true., &
               deepmsg,qual,ich,.false.,0)
       else
          call this%decode_callback(nutc,nsnr,dtxz,nfreqz,.true.,csync,       &
               .false.,blank,0.,ich,.false.,0)
       endif
    end if

    dtx=dtx1
    nfreq=nfreq1
    deepave=deepave1
    ich=ich1
    qave=qabest
    if (associated (this%decode_callback)) then
       if(int(qave).ge.nq1) then
          call this%decode_callback(nutc,nsnr,dtx,nfreq,.true.,csync,.true.,  &
               deepave,qave,ich,.true.,ndeepave)
       endif
    end if

990 return
  end subroutine wsjt4

  subroutine avg4(this,nutc,snrsync,dtxx,flip,nfreq,mode4,ntol,ndepth,neme,   &
       mycall,hiscall,hisgrid,nfanoave,avemsg,qave,deepave,ichbest,ndeepave)

    ! Decodes averaged JT4 data

    use jt4
    class(jt4_decoder), intent(inout) :: this

    character*22 avemsg,deepave,deepbest
    character mycall*12,hiscall*12,hisgrid*6
    character*1 csync,cused(64)
    real sym(207,7)
    integer iused(64)
    logical first
    data first/.true./
    save

    if(first) then
       iutc=-1
       nfsave=0
       dtdiff=0.2
       first=.false.
    endif

    do i=1,64
       if(nutc.eq.iutc(i) .and. abs(nhz-nfsave(i)).le.ntol) go to 10
    enddo

    ! Save data for message averaging
    iutc(nsave)=nutc
    syncsave(nsave)=snrsync
    dtsave(nsave)=dtxx
    nfsave(nsave)=nfreq
    flipsave(nsave)=flip
    ppsave(1:207,1:7,nsave)=rsymbol(1:207,1:7)  

10  sym=0.
    syncsum=0.
    dtsum=0.
    nfsum=0
    nsum=0

    do i=1,64
       cused(i)='.'
       if(iutc(i).lt.0) cycle
       if(mod(iutc(i),2).ne.mod(nutc,2)) cycle  !Use only same (odd/even) sequence
       if(abs(dtxx-dtsave(i)).gt.dtdiff) cycle  !DT must match
       if(abs(nfreq-nfsave(i)).gt.ntol) cycle   !Freq must match
       if(flip.ne.flipsave(i)) cycle            !Sync (*/#) must match
       sym(1:207,1:7)=sym(1:207,1:7) +  ppsave(1:207,1:7,i)
       syncsum=syncsum + syncsave(i)
       dtsum=dtsum + dtsave(i)
       nfsum=nfsum + nfsave(i)
       cused(i)='$'
       nsum=nsum+1
       iused(nsum)=i
    enddo
    if(nsum.lt.64) iused(nsum+1)=0

    syncave=0.
    dtave=0.
    fave=0.
    if(nsum.gt.0) then
       sym=sym/nsum
       syncave=syncsum/nsum
       dtave=dtsum/nsum
       fave=float(nfsum)/nsum
    endif

    !  rewind 80
    do i=1,nsave
       csync='*'
       if(flipsave(i).lt.0.0) csync='#'
       if (associated (this%average_callback)) then
          call this%average_callback(cused(i) .eq. '$',iutc(i),               &
               syncsave(i) - 5.,dtsave(i),nfsave(i),flipsave(i) .lt.0.)
       end if
!       write(14,1000) cused(i),iutc(i),syncsave(i)-5.0,dtsave(i),nfsave(i),csync
!1000   format(a1,i5.4,f6.1,f6.2,i6,1x,a1)
    enddo

    sqt=0.
    sqf=0.
    do j=1,64
       i=iused(j)
       if(i.eq.0) exit
       csync='*'
       if(flipsave(i).lt.0.0) csync='#'
       !     write(80,3001) i,iutc(i),syncsave(i),dtsave(i),nfsave(i),csync
       !3001 format(i3,i6.4,f6.1,f6.2,i6,1x,a1)
       sqt=sqt + (dtsave(i)-dtave)**2
       sqf=sqf + (nfsave(i)-fave)**2
    enddo
    rmst=0.
    rmsf=0.
    if(nsum.ge.2) then
       rmst=sqrt(sqt/(nsum-1))
       rmsf=sqrt(sqf/(nsum-1))
    endif
    !  write(80,3002)
    !3002 format(16x,'----- -----')
    !  write(80,3003) dtave,nint(fave)
    !  write(80,3003) rmst,nint(rmsf)
    !3003 format(15x,f6.2,i6)
    !  flush(80)

    !  nadd=nused*mode4
    kbest=ich1
    do k=ich1,ich2
       call extract4(sym(1,k),ncount,avemsg)     !Do the Fano decode
       nfanoave=0
       if(ncount.ge.0) then
          ichbest=k
          nfanoave=nsum
          go to 900
       endif
       if(nch(k).ge.mode4) exit
    enddo

    deepave='                      '
    qave=0.

    ! Possibly should pass nadd=nused, also ?
    if(ndepth.ge.3) then
       flipx=1.0                     !Normal flip not relevant for ave msg
       qbest=0.
       do k=ich1,ich2
          call deep4(sym(2,k),neme,flipx,mycall,hiscall,hisgrid,deepave,qave)
          !        write(82,3101) nutc,sym(51:53,k),flipx,k,qave,deepave
          !3101    format(i4.4,4f8.1,i3,f7.2,2x,a22)
          if(qave.gt.qbest) then
             qbest=qave
             deepbest=deepave
             kbest=k
             ndeepave=nsum
          endif
          if(nch(k).ge.mode4) exit
       enddo

       deepave=deepbest
       qave=qbest
       ichbest=kbest
    endif

900 return
  end subroutine avg4
end module jt4_decode
