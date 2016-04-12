module jt65_decode

  integer, parameter :: NSZ=3413, NZMAX=60*12000

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
          width,decoded,ft,qual,nsmo,nsum,minsync,nsubmode,naggressive)

       import jt65_decoder
       implicit none
       class(jt65_decoder), intent(inout) :: this
       integer, intent(in) :: utc
       real, intent(in) :: sync
       integer, intent(in) :: snr
       real, intent(in) :: dt
       integer, intent(in) :: freq
       integer, intent(in) :: drift
       real, intent(in) :: width
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
       ndepth,clearave,mycall,hiscall,hisgrid,nexp_decode)

    !  Process dd0() data to find and decode JT65 signals.

    use jt65_mod
    use timer_module, only: timer

    include 'constants.f90'

    class(jt65_decoder), intent(inout) :: this
    procedure(jt65_decode_callback) :: callback
    real, intent(in) :: dd0(NZMAX)
    integer, intent(in) :: npts, nutc, nf1, nf2, nfqso, ntol     &
         , nsubmode, minsync, n2pass, ntrials, naggressive, ndepth      &
         , nexp_decode
    logical, intent(in) :: newdat, nagain, nrobust, clearave
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
    logical :: first_time,robust,prtavg,single_decode

    integer h0(0:11),d0(0:11)
    real r0(0:11)
    common/decstats/ntry65a,ntry65b,n65a,n65b,num9,numfano
    common/steve/thresh0

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
       single_decode=iand(nexp_decode,32).ne.0
       if(single_decode .or. (naggressive.gt.0 .and. ntol.lt.1000)) then
          nfa=max(200,nfqso-ntol)
          nfb=min(4000,nfqso+ntol)
          thresh0=1.0
       endif
       df=12000.0/8192.0                     !df = 1.465 Hz
       if(single_decode) then
          ia=max(1,nint(nfa/df)-ntol)
          ib=min(NSZ,nint(nfb/df)+ntol)
          nz=ib-ia+1
          call lorentzian(savg(ia),nz,a)
          baseline=a(1)
          amp=a(2)
          f0=(a(3)+ia-1)*df
          width=a(4)*df
!          write(*,3001) baseline,amp,f0,width
!3001      format(4f10.3)
       endif

       ! robust = .false.: use float ccf. Only if ncand>50 fall back to robust (1-bit) ccf
       ! robust = .true. : use only robust (1-bit) ccf
       ncand=0
       if(.not.robust) then
          call timer('sync65  ',0)
          call sync65(ss,nfa,nfb,naggressive,ntol,nhsym,ca,ncand,0,    &
               single_decode)

          call timer('sync65  ',1)
       endif
       if(ncand.gt.50) robust=.true.
       if(robust) then
          ncand=0
          call timer('sync65  ',0)
          call sync65(ss,nfa,nfb,naggressive,ntol,nhsym,ca,ncand,1,   &
               single_decode)
          call timer('sync65  ',1)
       endif

! If a candidate was found within +/- ntol of nfqso, move it into ca(1).
       call fqso_first(nfqso,ntol,ca,ncand)
       if(single_decode) ncand=1
       nvec=ntrials
       if(ncand.gt.75) then
          !      write(*,*) 'Pass ',ipass,' ncandidates too large ',ncand
          nvec=100
       endif

       mode65=2**nsubmode
       nflip=1                             !### temporary ###
       nqd=0
       decoded0=""
       freq0=0.
       prtavg=.false.
       if(.not.nagain) nsum=0
       if(clearave) then
          nsum=0
          nsave=0
       endif

       do icand=1,ncand
          sync1=ca(icand)%sync
          dtx=ca(icand)%dt
          freq=ca(icand)%freq
          if(ipass.eq.1) ntry65a=ntry65a + 1
          if(ipass.eq.2) ntry65b=ntry65b + 1
          call timer('decod65a',0)
          call decode65a(dd,npts,first_time,nqd,freq,nflip,mode65,nvec,     &
               naggressive,ndepth,mycall,hiscall,hisgrid,nexp_decode,       &
               sync2,a,dtx,nft,qual,nhist,nsmo,decoded)
          call timer('decod65a',1)
          if(nft.ne.0) nsum=1

!          ncandidates=param(0)
          nhard_min=param(1)
!          nsoft_min=param(2)
!          nera_best=param(3)
          nrtt1000=param(4)
          ntotal_min=param(5)
!          ntry=param(6)
!          nq1000=param(7)
!          npp1=param(8)
          nsmo=param(9)

          nfreq=nint(freq+a(1))
          ndrift=nint(2.0*a(2))
          if(single_decode) then
             s2db=sync1 - 30.0 + db(width/3.3)        !### VHF/UHF/microwave
          else
             s2db=10.0*log10(sync2) - 35             !### empirical (HF) 
          endif
          nsnr=nint(s2db)
          if(nsnr.lt.-30) nsnr=-30
          if(nsnr.gt.-1) nsnr=-1
          nftt=0

          if(nft.ne.1 .and. iand(ndepth,16).eq.16 .and. (.not.prtavg)) then
! Single-sequence FT decode failed, so try for an average FT decode.
             if(nutc.ne.nutc0 .or. abs(nfreq-nfreq0).gt.ntol) then
! This is a new minute or a new frequency, so call avg65.
                nutc0=nutc
                nfreq0=nfreq
                nsave=nsave+1
                nsave=mod(nsave-1,64)+1
                call avg65(nutc,nsave,sync1,dtx,nflip,nfreq,mode65,ntol,    &
                     ndepth,ntrials,naggressive,clearave,neme,mycall,      &
                     hiscall,hisgrid,nftt,avemsg,qave,deepave,nsum,ndeepave)
                nsmo=param(9)
                nqave=qave

                if (associated(this%callback) .and. nsum.ge.2) then
                   call this%callback(nutc,sync1,nsnr,dtx-1.0,nfreq,ndrift,  &
                        width,avemsg,nftt,nqave,nsmo,nsum,minsync,nsubmode,  &
                        naggressive)
                   prtavg=.true.
                   cycle
                end if

             endif
          endif

          if(nftt.eq.1) then
             nft=1
             decoded=avemsg
             go to 5
          endif
          n=naggressive
          rtt=0.001*nrtt1000
          if(nft.lt.2 .and. minsync.ge.0) then
             if(nhard_min.gt.50) cycle
             if(nhard_min.gt.h0(n)) cycle
             if(ntotal_min.gt.d0(n)) cycle
             if(rtt.gt.r0(n)) cycle
          endif

5         continue
          if(decoded.eq.decoded0 .and. abs(freq-freq0).lt. 3.0 .and.    &
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
                   call this%callback(nutc,sync1,nsnr,dtx-1.0,nfreq,ndrift,  &
                        width,decoded,nft,nqual,nsmo,nsum,minsync,nsubmode,  &
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
       ntrials,naggressive,clearave,neme,mycall,hiscall,hisgrid,nftt,      &
       avemsg,qave,deepave,nsum,ndeepave)

! Decodes averaged JT65 data

    use jt65_mod
    parameter (MAXAVE=64)
    character*22 avemsg,deepave,deepbest
    character mycall*12,hiscall*12,hisgrid*6
    character*1 csync,cused(64)
    integer iused(64)
! Accumulated data for message averaging
    integer iutc(MAXAVE)
    integer nfsave(MAXAVE)
    integer nflipsave(MAXAVE)
    real s1b(-255:256,126)
    real s1save(-255:256,126,MAXAVE)
    real s2(66,126)
    real s3save(64,63,MAXAVE)
    real s3b(64,63)
    real s3c(64,63)
    real dtsave(MAXAVE)
    real syncsave(MAXAVE)
    logical first,clearave
    data first/.true./
    save

    if(first .or. clearave) then
       iutc=-1
       nfsave=0
       dtdiff=0.2
       first=.false.
       s3save=0.
       s1save=0.
       nsave=1           !### ???
    endif

    do i=1,64
       if(nutc.eq.iutc(i) .and. abs(nhz-nfsave(i)).le.ntol) go to 10
    enddo

! Save data for message averaging
    iutc(nsave)=nutc
    syncsave(nsave)=snrsync
    dtsave(nsave)=dtxx
    nfsave(nsave)=nfreq
    nflipsave(nsave)=nflip
    s1save(-255:256,1:126,nsave)=s1
    s3save(1:64,1:63,nsave)=s3a

10  syncsum=0.
    dtsum=0.
    nfsum=0
    nsum=0
    s1b=0.
    s3b=0.
    s3c=0.

    do i=1,MAXAVE                               !Consider all saved spectra
       cused(i)='.'
       if(iutc(i).lt.0) cycle
       if(mod(iutc(i),2).ne.mod(nutc,2)) cycle  !Use only same (odd/even) seq
       if(abs(dtxx-dtsave(i)).gt.dtdiff) cycle  !DT must match
       if(abs(nfreq-nfsave(i)).gt.ntol) cycle   !Freq must match
       if(nflip.ne.nflipsave(i)) cycle          !Sync type (*/#) must match
       s3b=s3b + s3save(1:64,1:63,i)
       s1b=s1b + s1save(-255:256,1:126,i)
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
       syncave=syncsum/nsum
       dtave=dtsum/nsum
       fave=float(nfsum)/nsum
    endif

    do i=1,nsave
       csync='*'
       if(nflipsave(i).lt.0.0) csync='#'
       write(14,1000) cused(i),iutc(i),syncsave(i),dtsave(i)-1.0,nfsave(i),csync
1000   format(a1,i5.4,f6.1,f6.2,i6,1x,a1)
    enddo
    if(nsum.lt.2) go to 900

    nftt=0
    df=1378.125/512.0

! Do the smoothing loop
    qualbest=0.
    minsmo=0
    maxsmo=0
    if(mode65.ge.2) then
       minsmo=nint(width/df)
       maxsmo=2*minsmo
    endif
    nn=0
    do ismo=minsmo,maxsmo
       if(ismo.gt.0) then
          do j=1,126
             call smo121(s1b(-255,j),512)
             if(j.eq.1) nn=nn+1
             if(nn.ge.4) then
                call smo121(s1b(-255,j),512)
                if(j.eq.1) nn=nn+1
             endif
          enddo
       endif

       do i=1,66
          jj=i
          if(mode65.eq.2) jj=2*i-1
          if(mode65.eq.4) then
             ff=4*(i-1)*df - 355.297852
             jj=nint(ff/df)+1
          endif
          s2(i,1:126)=s1b(jj,1:126)
       enddo

       do j=1,63
          k=mdat(j)                       !Points to data symbol
          if(nflip.lt.0) k=mdat2(j)
          do i=1,64
             s3c(i,j)=4.e-5*s2(i+2,k)
          enddo
       enddo

       nadd=nsum*ismo
       call extract(s3c,nadd,mode65,ntrials,naggressive,ndepth,mycall,    &
            hiscall,hisgrid,nexp_decode,ncount,nhist,avemsg,ltext,nftt,qual)
       if(nftt.eq.1) then
          nsmo=ismo
          param(9)=nsmo
          go to 900
       else if(nftt.eq.2) then
          if(qual.gt.qualbest) then
             deepbest=avemsg
             qualbest=qual
             nnbest=nn
             nsmobest=ismo
             nfttbest=nftt
          endif
       endif
    enddo

    if(nfttbest.eq.2) then
       avemsg=deepbest       !### ???
       deepave=deepbest
       qave=qualbest
       nsmo=nsmobest
       param(9)=nsmo
       nftt=nfttbest
    endif
900 continue
!    write(*,3301) 'Z',nftt,nsave,nsum,nsmo,qave,avemsg
!3301 format(a1,4i3,f7.1,1x,a22)

    return
  end subroutine avg65

end module jt65_decode
