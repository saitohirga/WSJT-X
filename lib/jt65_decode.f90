module jt65_decode

  type :: jt65_decoder
     procedure(jt65_decode_callback), pointer :: callback => null()
   contains
     procedure :: decode
  end type jt65_decoder

  !
  ! Callback function to be called with each decode
  !
  abstract interface
     subroutine jt65_decode_callback (this, utc, sync, snr, dt, freq, drift,          &
          decoded, ft, qual, candidates, tries, total_min, hard_min, aggression)
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
       integer, intent(in) :: candidates
       integer, intent(in) :: tries
       integer, intent(in) :: total_min
       integer, intent(in) :: hard_min
       integer, intent(in) :: aggression
     end subroutine jt65_decode_callback
  end interface

contains

  subroutine decode(this,callback,dd0,npts,newdat,nutc,nf1,nf2,nfqso,ntol,nsubmode,   &
       minsync,nagain,n2pass,nrobust,ntrials,naggressive,ndepth,       &
       mycall,hiscall,hisgrid,nexp_decode)

    !  Process dd0() data to find and decode JT65 signals.

    use timer_module, only: timer

    include 'constants.f90'
    parameter (NSZ=3413,NZMAX=60*12000)
    parameter (NFFT=1000)

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
    character*22 decoded,decoded0
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
    logical :: first_time, robust
    common/decstats/ntry65a,ntry65b,n65a,n65b,num9,numfano
    common/steve/thresh0
    common/test000/ncandidates,nhard_min,nsoft_min,nera_best,nsofter_min,   &
         ntotal_min,ntry,nq1000,ntot         !### TEST ONLY ###
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

       do icand=1,ncand
          freq=ca(icand)%freq
          dtx=ca(icand)%dt
          sync1=ca(icand)%sync
          if(ipass.eq.1) ntry65a=ntry65a + 1
          if(ipass.eq.2) ntry65b=ntry65b + 1
          call timer('decod65a',0)
          call decode65a(dd,npts,first_time,nqd,freq,nflip,mode65,nvec,     &
               naggressive,ndepth,mycall,hiscall,hisgrid,nexp_decode,   &
               sync2,a,dtx,nft,qual,nhist,decoded)
          call timer('decod65a',1)

          !### Suppress false decodes in crowded HF bands ###
          if(naggressive.eq.0 .and. ntrials.le.10000) then
             if(ntry.eq.ntrials .or. ncandidates.eq.100) then
                if(nhard_min.ge.42 .or. ntotal_min.ge.71) cycle
             endif
          endif

          if(decoded.eq.decoded0 .and. abs(freq-freq0).lt. 3.0 .and.    &
               minsync.ge.0) cycle                  !Don't display dupes
          if(decoded.ne.'                      ' .or. minsync.lt.0) then
             if( nsubtract .eq. 1 ) then
                call timer('subtr65 ',0)
                call subtract65(dd,npts,freq,dtx)
                call timer('subtr65 ',1)
             endif
             nfreq=nint(freq+a(1))
             ndrift=nint(2.0*a(2))
             s2db=10.0*log10(sync2) - 35             !### empirical ###
             nsnr=nint(s2db)
             if(nsnr.lt.-30) nsnr=-30
             if(nsnr.gt.-1) nsnr=-1

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
                !          if(nqual.gt.10) nqual=10
                if (associated(this%callback)) then
                   call this%callback(nutc,sync1,nsnr,dtx-1.0,nfreq,ndrift,decoded &
                        ,nft,nqual,ncandidates,ntry,ntotal_min,nhard_min,naggressive)
                end if
             endif
             decoded0=decoded
             freq0=freq
             if(decoded0.eq.'                      ') decoded0='*'
          endif
       enddo                                 !candidate loop
       if(ndecoded.lt.1) exit
    enddo                                   !two-pass loop

    return
  end subroutine decode

end module jt65_decode
