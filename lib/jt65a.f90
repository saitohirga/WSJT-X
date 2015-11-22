subroutine jt65a(dd0,npts,newdat,nutc,nf1,nf2,nfqso,ntol,nsubmode,   &
     minsync,nagain,n2pass,nrobust,ntrials,naggressive,ndepth,ndecoded)

!  Process dd0() data to find and decode JT65 signals.

  parameter (NSZ=3413,NZMAX=60*12000)
  parameter (NFFT=1000)
  real dd0(NZMAX)
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
  type(candidate) ca(300), car(300)
  type decode
     real freq
     real dt
     real sync
     character*22 decoded
  end type decode
  type(decode) dec(30)
  common/decstats/ntry65a,ntry65b,n65a,n65b,num9,numfano
  common/steve/thresh0
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

! OPTION 2 is not used at present. Checkbox in Advanced setup selects nrobust=1
! nrobust = 0: use only float ccf
! nrobust = 1: use only robust (1-bit) ccf
! nrobust = 2: use algorithm below
!              find ncand using float ccf and ncandr using 1-bit ccf
!              if ncand>50, use robust ccf
!              if ncand<25 and ncandr<25, form union of both sets
!              else, use float ccf
    if( (nrobust.eq.0) .or. (nrobust.eq.2) ) then
      ncand=0
      call timer('sync65  ',0)
      call sync65(ss,nfa,nfb,nhsym,ca,ncand,0)
      call timer('sync65  ',1)
    endif

    if( (nrobust.eq.1) .or. (nrobust.eq.2) ) then
      ncandr=0
      call timer('sync65  ',0)
      call sync65(ss,nfa,nfb,nhsym,car,ncandr,1)
      call timer('sync65  ',1)
    endif
    if( (nrobust.eq.1) .or. ((nrobust.eq.2) .and. (ncand.gt.50)) ) then
      ncand=ncandr
      do i=1,ncand
        ca(i)=car(i)
      enddo
    elseif(nrobust.eq.2.and.ncand.le.25.and.ncandr.le.25) then
      do icand=1,ncand ! combine ca and car, without dupes
        ndupe=0
        do j=1,ncandr
          if( abs(ca(icand)%freq-car(j)%freq) .lt. 1.0 ) then
            ndupe=1
          endif
        enddo
        if( ndupe.eq.0 ) then
          ncandr=ncandr+1
          car(ncandr)=ca(icand)
        endif
      enddo
      ncand=ncandr
      do i=1,ncand
        ca(i)=car(i)
      enddo
    endif

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

    do icand=1,ncand
      freq=ca(icand)%freq
      dtx=ca(icand)%dt
      sync1=ca(icand)%sync

      if(ipass.eq.1) ntry65a=ntry65a + 1
      if(ipass.eq.2) ntry65b=ntry65b + 1
      call timer('decod65a',0)
      call decode65a(dd,npts,newdat,nqd,freq,nflip,mode65,nvec,     &
           naggressive,ndepth,sync2,a,dtx,nsf,nhist,decoded)
      call timer('decod65a',1)
!write(*,*) icand,freq+a(1),dtx,sync1,sync2
      if(decoded.eq.decoded0) cycle            !Don't display dupes

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
          if( decoded==dec(i)%decoded ) ndupe=1
        enddo
        if(ndupe.ne.1) then
          if(ipass.eq.1) n65a=n65a + 1
          if(ipass.eq.2) n65b=n65b + 1
          ndecoded=ndecoded+1
          dec(ndecoded)%freq=freq+a(1)
          dec(ndecoded)%dt=dtx
          dec(ndecoded)%sync=sync2
          dec(ndecoded)%decoded=decoded
          write(*,1010) nutc,nsnr,dtx-1.0,nfreq,decoded
1010      format(i4.4,i4,f5.1,i5,1x,'#',1x,a22)
          write(13,1012) nutc,nint(sync1),nsnr,dtx-1.0,float(nfreq),ndrift,  &
             decoded,nsf
1012      format(i4.4,i4,i5,f6.1,f8.0,i4,3x,a22,' JT65',i4)
          call flush(6)
          call flush(13)
        endif
!$omp end critical(decode_results)
      endif
    enddo                                 !candidate loop
    if(ndecoded.lt.1) exit
  enddo                                   !two-pass loop

  return
end subroutine jt65a
