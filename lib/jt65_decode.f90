module jt65_decode

  integer, parameter :: NSZ=3413, NZMAX=60*12000, NFFT=1000

  type :: jt65_decoder
     procedure(jt65_decode_callback), pointer :: callback => null()
   contains
     procedure :: decode
  end type jt65_decoder

  !
  ! Callback function to be called with each decode
  !
  abstract interface
     subroutine jt65_decode_callback(this,utc,sync,snr,dt,freq,drift,     &
          decoded,ft,qual,nsmo,nsum,minsync,nsubmode,naggressive)

       import jt65_decoder
       implicit none
       class(jt65_decoder), intent(inout) :: this
       integer, intent(in) :: utc
       real, intent(in) :: sync
       integer, intent(in) :: snr
       real, intent(in) :: dt
       integer, intent(in) :: freq
       integer, intent(in) :: drift
       character(len=22), intent(in) :: decoded
       integer, intent(in) :: ft
       integer, intent(in) :: qual
       integer, intent(in) :: nsmo
       integer, intent(in) :: nsum
       integer, intent(in) :: minsync
       integer, intent(in) :: nsubmode
       integer, intent(in) :: naggressive

     end subroutine jt65_decode_callback
  end interface

contains

  subroutine decode(this,callback,dd0,npts,newdat,nutc,nf1,nf2,nfqso,     &
       ntol,nsubmode,minsync,nagain,n2pass,nrobust,ntrials,naggressive,   &
       ndepth,nclearave,mycall,hiscall,hisgrid,nexp_decode)

    !  Process dd0() data to find and decode JT65 signals.

    use timer_module, only: timer

    include 'constants.f90'

    class(jt65_decoder), intent(inout) :: this
    procedure(jt65_decode_callback) :: callback
    real, intent(in) :: dd0(NZMAX)
    integer, intent(in) :: npts, nutc, nf1, nf2, nfqso, ntol     &
         , nsubmode, minsync, n2pass, ntrials, naggressive, ndepth      &
         , nexp_decode
    logical, intent(in) :: newdat, nagain, nrobust
    character(len=12), intent(in) :: mycall, hiscall
    character(len=6), intent(in) :: hisgrid

    real dd(NZMAX)
    real ss(322,NSZ)
    real savg(NSZ)
    real a(5)
    character*22 decoded,decoded0,avemsg,deepave
    type candidate
       real freq
       real dt
       real sync
    end type candidate
    type(candidate) ca(300)
    type accepted_decode
       real freq
       real dt
       real sync
       character*22 decoded
    end type accepted_decode
    type(accepted_decode) dec(50)
    logical :: first_time, robust, prtavg

    integer h0(0:11),d0(0:11)
    real r0(0:11)
    common/decstats/ntry65a,ntry65b,n65a,n65b,num9,numfano
    common/steve/thresh0
    common/test000/ncandidates,nhard_min,nsoft_min,nera_best,nrtt1000,   &
         ntotal_min,ntry,nq1000,npp1,nsmo         !### TEST ONLY ###

!            0  1  2  3  4  5  6  7  8  9 10 11
    data h0/41,42,43,43,44,45,46,47,48,48,49,49/
    data d0/71,72,73,74,76,77,78,80,81,82,83,83/

!             0    1    2    3    4    5    6    7    8    9   10   11
    data r0/0.70,0.72,0.74,0.76,0.78,0.80,0.82,0.84,0.86,0.88,0.90,0.90/
    data nutc0/-999/,nfreq0/-999/,nsave/0/
    save

    this%callback => callback
    first_time=newdat
    robust=nrobust
    dd=dd0
    ndecoded=0
    do ipass=1,n2pass                             ! 2-pass decoding loop
       first_time=.true.
       if(ipass.eq.1) then                         !first-pass parameters
          thresh0=2.5
          nsubtract=1
       elseif( ipass.eq.2 ) then !second-pass parameters
          thresh0=2.5
          nsubtract=0
       endif
       if(n2pass.lt.2) nsubtract=0

       !  if(newdat) then
       call timer('symsp65 ',0)
       ss=0.
       call symspec65(dd,npts,ss,nhsym,savg)    !Get normalized symbol spectra
       call timer('symsp65 ',1)
       !  endif
       nfa=nf1
       nfb=nf2
       if(naggressive.gt.0 .and. ntol.lt.1000) then
          nfa=max(200,nfqso-ntol)
          nfb=min(4000,nfqso+ntol)
          thresh0=1.0
       endif

       ! robust = .false.: use float ccf. Only if ncand>50 fall back to robust (1-bit) ccf
       ! robust = .true. : use only robust (1-bit) ccf
       ncand=0
       if(.not.robust) then
          call timer('sync65  ',0)
          call sync65(ss,nfa,nfb,naggressive,ntol,nhsym,ca,ncand,0)
          call timer('sync65  ',1)
       endif
       if(ncand.gt.50) robust=.true.
       if(robust) then
          ncand=0
          call timer('sync65  ',0)
          call sync65(ss,nfa,nfb,naggressive,ntol,nhsym,ca,ncand,1)
          call timer('sync65  ',1)
       endif

       call fqso_first(nfqso,ntol,ca,ncand)

       nvec=ntrials
       if(ncand.gt.75) then
          !      write(*,*) 'Pass ',ipass,' ncandidates too large ',ncand
          nvec=100
       endif

       df=12000.0/NFFT                     !df = 12000.0/8192 = 1.465 Hz
       mode65=2**nsubmode
       nflip=1                             !### temporary ###
       nqd=0
       decoded0=""
       freq0=0.
       prtavg=.false.

       do icand=1,ncand
          freq=ca(icand)%freq
          dtx=ca(icand)%dt
          sync1=ca(icand)%sync
          if(ipass.eq.1) ntry65a=ntry65a + 1
          if(ipass.eq.2) ntry65b=ntry65b + 1
          call timer('decod65a',0)
          call decode65a(dd,npts,first_time,nqd,freq,nflip,mode65,nvec,     &
               naggressive,ndepth,mycall,hiscall,hisgrid,nexp_decode,   &
               sync2,a,dtx,nft,qual,nhist,nsmo,decoded)
          call timer('decod65a',1)
          nfreq=nint(freq+a(1))
          ndrift=nint(2.0*a(2))
          s2db=10.0*log10(sync2) - 35             !### empirical ###
          nsnr=nint(s2db)
          if(nsnr.lt.-30) nsnr=-30
          if(nsnr.gt.-1) nsnr=-1

          if(nft.ne.1 .and. ndepth.ge.4 .and. (.not.prtavg)) then
! Single-sequence FT decode failed, so try for an average FT decode.
             if(nutc.ne.nutc0 .or. abs(nfreq-nfreq0).gt.ntol) then
! This is a new minute or a new frequency, so call avg65.
                nutc0=nutc
                nfreq0=nfreq
                nsave=nsave+1
                nsave=mod(nsave-1,64)+1
                call avg65(nutc,nsave,sync1,dtx,nflip,nfreq,mode65,ntol,    &
                     ndepth,nclearave,neme,mycall,hiscall,hisgrid,nftt,     &
                     avemsg,qave,deepave,nsum,ndeepave)

                if (associated(this%callback)) then
!                   print*,'FT1 failed; nsave,nftt: ',nsave,nftt
!                   print*,'A',nftt,nsum,nsmo
                   call this%callback(nutc,sync1,nsnr,dtx-1.0,nfreq,ndrift,  &
                        avemsg,nftt,nqual,nsmo,nsum,minsync,nsubmode,       &
                        naggressive)
                   prtavg=.true.
                   cycle
                end if

             endif
          endif
!          if(nftt.eq.1) then
!             nft=1
!             decoded=avemsg
!             go to 5
!          endif

          n=naggressive
          rtt=0.001*nrtt1000
          if(nft.lt.2) then
             if(nhard_min.gt.50) cycle
             if(nhard_min.gt.h0(n)) cycle
             if(ntotal_min.gt.d0(n)) cycle
             if(rtt.gt.r0(n)) cycle
          endif

5         if(decoded.eq.decoded0 .and. abs(freq-freq0).lt. 3.0 .and.    &
               minsync.ge.0) cycle                  !Don't display dupes

          if(decoded.ne.'                      ' .or. minsync.lt.0) then
             if( nsubtract .eq. 1 ) then
                call timer('subtr65 ',0)
                call subtract65(dd,npts,freq,dtx)
                call timer('subtr65 ',1)
             endif

             ndupe=0 ! de-dedupe
             do i=1, ndecoded
                if(decoded==dec(i)%decoded) then
                   ndupe=1
                   exit
                endif
             enddo
             if(ndupe.ne.1 .or. minsync.lt.0) then
                if(ipass.eq.1) n65a=n65a + 1
                if(ipass.eq.2) n65b=n65b + 1
                ndecoded=ndecoded+1
                dec(ndecoded)%freq=freq+a(1)
                dec(ndecoded)%dt=dtx
                dec(ndecoded)%sync=sync2
                dec(ndecoded)%decoded=decoded
                nqual=min(qual,9999.0)
                if (associated(this%callback)) then
!                   print*,'B',nsave,nft,nsmo,nsum
                   call this%callback(nutc,sync1,nsnr,dtx-1.0,nfreq,ndrift,  &
                        decoded,nft,nqual,nsmo,nsum,minsync,nsubmode,        &
                        naggressive)
                end if
             endif
             decoded0=decoded
             freq0=freq
             if(decoded0.eq.'                      ') decoded0='*'
          endif
       enddo                                 !Candidate loop
       if(ndecoded.lt.1) exit
    enddo                                    !Two-pass loop

    return
  end subroutine decode

  subroutine avg65(nutc,nsave,snrsync,dtxx,nflip,nfreq,mode65,ntol,ndepth,  &
       nclearave,neme,mycall,hiscall,hisgrid,nftt,avemsg,qave,deepave,      &
       nsum,ndeepave)

! Decodes averaged JT65 data

    parameter (MAXAVE=64)
    character*22 avemsg,deepave,deepbest
    character mycall*12,hiscall*12,hisgrid*6
    character*1 csync,cused(64)
    integer iused(64)
! Accumulated data for message averaging
    integer iutc(MAXAVE)
    integer nfsave(MAXAVE)
    integer listutc(10)
    integer nflipsave(MAXAVE)
    real s3save(64,63,MAXAVE)
    real s3b(64,63)
    real dtsave(MAXAVE)
    real syncsave(MAXAVE)
    logical first
    data first/.true./
    common/test001/s3a(64,63)
    save

    if(first .or. (nclearave.eq.1)) then
       iutc=-1
       nfsave=0
       dtdiff=0.2
       first=.false.
    endif
    nclearave=0

    do i=1,64
       if(nutc.eq.iutc(i) .and. abs(nhz-nfsave(i)).le.ntol) go to 10
    enddo

    ! Save data for message averaging
    iutc(nsave)=nutc
    syncsave(nsave)=snrsync
    dtsave(nsave)=dtxx
    nfsave(nsave)=nfreq
    nflipsave(nsave)=nflip
    s3save(1:64,1:63,nsave)=s3a

10  sym=0.
    syncsum=0.
    dtsum=0.
    nfsum=0
    nsum=0

    do i=1,64
       cused(i)='.'
       if(iutc(i).lt.0) cycle
       if(mod(iutc(i),2).ne.mod(nutc,2)) cycle  !Use only same (odd/even) seq
       if(abs(dtxx-dtsave(i)).gt.dtdiff) cycle  !DT must match
       if(abs(nfreq-nfsave(i)).gt.ntol) cycle   !Freq must match
       if(nflip.ne.nflipsave(i)) cycle          !Sync type (*/#) must match
       s3b=s3b + s3save(1:64,1:63,i)
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

    do i=1,nsave
       csync='*'
       if(nflipsave(i).lt.0.0) csync='#'
       write(61,1000) cused(i),iutc(i),syncsave(i),dtsave(i),nfsave(i),csync
1000   format(a1,i5.4,f6.1,f6.2,i6,1x,a1)
    enddo

    rewind 62
    sqt=0.
    sqf=0.
    do j=1,64
       i=iused(j)
       if(i.eq.0) exit
       csync='*'
       if(nflipsave(i).lt.0) csync='#'
       write(62,3001) i,iutc(i),syncsave(i),dtsave(i),nfsave(i),csync
3001   format(i3,i6.4,f6.1,f6.2,i6,1x,a1)
       sqt=sqt + (dtsave(i)-dtave)**2
       sqf=sqf + (nfsave(i)-fave)**2
    enddo
    rmst=0.
    rmsf=0.
    if(nsum.ge.2) then
       rmst=sqrt(sqt/(nsum-1))
       rmsf=sqrt(sqf/(nsum-1))
    endif
    write(62,3002)
3002 format(16x,'----- -----')
    write(62,3003) dtave,nint(fave)
    write(62,3003) rmst,nint(rmsf)
3003 format(15x,f6.2,i6)
    flush(62)

    nadd=nsum*mode65
    nftt=0
!###
    ntrials=3000
    naggressive=10
    hiscall='W9XYZ'
    hisgrid='EN37'
    nexp_decode=0    !### not used, anyway
!###
!    print*,'A',nadd,mode65,ntrials,naggressive,ndepth,mycall,    &
!         hiscall,hisgrid,nexp_decode

    call extract(s3b,nadd,mode65,ntrials,naggressive,ndepth,mycall,    &
     hiscall,hisgrid,nexp_decode,ncount,nhist,avemsg,ltext,nftt,qual)

    return
  end subroutine avg65

end module jt65_decode
