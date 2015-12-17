subroutine jt65a(dd0,npts,newdat,nutc,nf1,nf2,nfqso,ntol,nsubmode,   &
     minsync,nagain,n2pass,nrobust,ntrials,naggressive,ndepth,       &
     mycall,hiscall,hisgrid,nexp_decode,ndecoded)

!  Process dd0() data to find and decode JT65 signals.

  parameter (NSZ=3413,NZMAX=60*12000)
  parameter (NFFT=1000)
  real dd0(NZMAX)
  real dd(NZMAX)
  real ss(322,NSZ)
  real savg(NSZ)
  real a(5)
  character*22 decoded,decoded0
  character mycall*12,hiscall*12,hisgrid*6
  type candidate
     real freq
     real dt
     real sync
  end type candidate
  type(candidate) ca(300)
  type decode
     real freq
     real dt
     real sync
     character*22 decoded
  end type decode
  type(decode) dec(50)
  common/decstats/ntry65a,ntry65b,n65a,n65b,num9,numfano
  common/steve/thresh0
  common/test000/ncandidates,nhard_min,nsoft_min,nera_best,nsofter_min,   &
       ntotal_min,ntry,nq1000,ntot         !### TEST ONLY ###
  save

  dd=dd0
  ndecoded=0
  do ipass=1,n2pass                             ! 2-pass decoding loop
    newdat=1
    if(ipass.eq.1) then                         !first-pass parameters
      thresh0=2.5
      nsubtract=1
    elseif( ipass.eq.2 ) then !second-pass parameters
      thresh0=2.5
      nsubtract=0
    endif
    if(n2pass.lt.2) nsubtract=0

!  if(newdat.ne.0) then
     call timer('symsp65 ',0)
     ss=0.
     call symspec65(dd,npts,ss,nhsym,savg)    !Get normalized symbol spectra
     call timer('symsp65 ',1)
!  endif
     nfa=nf1
     nfb=nf2
!     nfa=max(200,nfqso-ntol)
!     nfb=min(4000,nfqso+ntol)

! nrobust = 0: use float ccf. Only if ncand>50 fall back to robust (1-bit) ccf
! nrobust = 1: use only robust (1-bit) ccf
    ncand=0
    if(nrobust.eq.0) then
      call timer('sync65  ',0)
      call sync65(ss,nfa,nfb,nhsym,ca,ncand,0)
      call timer('sync65  ',1)
    endif
    if(ncand.gt.50) nrobust=1
    if(nrobust.eq.1) then
      ncand=0
      call timer('sync65  ',0)
      call sync65(ss,nfa,nfb,nhsym,ca,ncand,1)
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
      call decode65a(dd,npts,newdat,nqd,freq,nflip,mode65,nvec,     &
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

! Serialize writes - see also decjt9.f90
!$omp critical(decode_results) 
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
          nqual=qual
!          if(nqual.gt.10) nqual=10
          write(*,1010) nutc,nsnr,dtx-1.0,nfreq,decoded
1010      format(i4.4,i4,f5.1,i5,1x,'#',1x,a22)
          write(13,1012) nutc,nint(sync1),nsnr,dtx-1.0,float(nfreq),ndrift,  &
             decoded,nft
1012      format(i4.4,i4,i5,f6.1,f8.0,i4,3x,a22,' JT65',i4)
          call flush(6)
          call flush(13)
          write(79,3001) nutc,nint(sync1),nsnr,dtx-1.0,nfreq,ncandidates,    &
               nhard_min,ntotal_min,ntry,naggressive,nft,nqual,decoded
3001      format(i4.4,i3,i4,f6.2,i5,i7,i3,i4,i8,i3,i2,i5,1x,a22)
          flush(79)
        endif
        decoded0=decoded
        freq0=freq
        if(decoded0.eq.'                      ') decoded0='*'
!$omp end critical(decode_results)
      endif
    enddo                                 !candidate loop
    if(ndecoded.lt.1) exit
  enddo                                   !two-pass loop

  return
end subroutine jt65a
