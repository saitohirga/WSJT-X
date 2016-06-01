subroutine jtmsk_decode(id2,narg,line)

! Decoder for JTMSK mode

  parameter (NMAX=30*12000)
  parameter (NFFTMAX=512*1024)
  parameter (NSPM=1404)                !Samples per JTMSK long message
  integer*2 id2(0:NMAX)                !Raw i*2 data, up to T/R = 30 s
  integer hist(0:32868)
  real d(0:NMAX)                       !Raw r*4 data
  real ty(NMAX/512)                    !Ping times
  real yellow(NMAX/512)
  complex c(NFFTMAX)                   !Complex (analytic) data
  complex cdat(24000)                  !Short segments, up to 2 s
  complex cdat2(24000)
  integer narg(0:14)                   !Arguments passed from calling pgm
  character*22 msg,msg0                !Decoded message
  character*80 line(100)               !Decodes passed back to caller
  equivalence (hist,d)

! Parameters from GUI are in narg():
  nutc=narg(0)                         !UTC
  npts=min(narg(1),NMAX)               !Number of samples in id2 (12000 Hz)
  newdat=narg(3)                       !1==> new data, compute symbol spectra
  minsync=narg(4)                      !Lower sync limit
  npick=narg(5)
  t0=0.001*narg(6)
  t1=0.001*narg(7)
  maxlines=narg(8)                     !Max # of decodes to return to caller
  nmode=narg(9)
  nrxfreq=narg(10)                     !Target Rx audio frequency (Hz)
  ntol=narg(11)                        !Search range, +/- ntol (Hz)
  nhashcalls=narg(12)
  naggressive=narg(14)
  nsnr0=-99
  nline=0
  line(1:100)(1:1)=char(0)
  msg0='                      '
  msg=msg0

  hist=0
  do i=0,npts-1
     n=abs(id2(i))
     hist(n)=hist(n)+1
  enddo
  ns=0
  do n=0,32768
     ns=ns+hist(n)
     if(ns.gt.npts/2) exit
  enddo
  fac=1.0/(1.5*n)
  d(0:npts-1)=fac*id2(0:npts-1)
!  rms=sqrt(dot_product(d(0:npts-1),d(0:npts-1))/npts)
!### Would it be better to set median rms to 1.0 ?
!  d(0:npts-1)=d(0:npts-1)/rms          !Normalize so that rms=1.0
  call mskdt(d,npts,ty,yellow,nyel)
  nyel=min(nyel,5)

  n=log(float(npts))/log(2.0) + 1.0
  nfft=min(2**n,1024*1024)
  call analytic(d,npts,nfft,c)         !Convert to analytic signal and filter

  nbefore=NSPM
  nafter=4*NSPM
! Process ping list (sorted by S/N) from top down.
  do n=1,nyel
     ia=ty(n)*12000.0 - nbefore
     if(ia.lt.1) ia=1
     ib=ia + nafter
     if(ib.gt.NFFTMAX) ib=NFFTMAX
     iz=ib-ia+1
     cdat2(1:iz)=c(ia:ib)               !Select nlen complex samples
     ja=ia/NSPM + 1
     jb=ib/NSPM
     t0=ia/12000.0

     do itry=1,21
        idf1=(itry/2) * 50
        if(mod(itry,2).eq.1) idf1=-idf1
        if(abs(idf1).gt.ntol) exit
        fpk=idf1 + nrxfreq
        call tweak1(cdat2,iz,1500.0-fpk,cdat)
        call syncmsk(cdat,iz,jpk,ipk,idf,rmax,snr,metric,msg)
        if(metric.eq.-9999) cycle             !No output if no significant sync
        if(msg(1:1).eq.' ') call jtmsk_short(cdat,iz,narg,tbest,idfpk,msg)
        if(msg(1:1).eq.'<' .and. naggressive.eq.0 .and.      &
             narg(13)/8.ne.narg(12)) msg='                      '
        if(msg(1:1).ne.' ') then
           if(msg.ne.msg0) then
              nline=nline+1
              nsnr0=-99
           endif
           freq=fpk+idf
           t0=(ia+jpk)/12000.0
           y=10.0**(0.1*(yellow(n)-1.5))
           nsnr=max(-5,nint(db(y)))
           if(nsnr.gt.nsnr0 .and. nline.gt.0) then
              call rectify_msk(cdat2(jpk:jpk+NSPM-1),msg,narg(13),freq2)
              freq=freq2
              if(msg(1:1).eq.'<') freq=freq2+idfpk
!### Check freq values !!!
              write(line(nline),1020) nutc,nsnr,t0,nint(freq),msg
1020          format(i6.6,i4,f5.1,i5,' & ',a22)
              nsnr0=nsnr
              go to 900
           endif
           msg0=msg
           if(nline.ge.maxlines) go to 900
        endif
     enddo
!     print*,'c',nutc,n,nint(yellow(n)-4.0),freq,freq2
  enddo

900 continue
!  print*,'d',nutc,n,nint(yellow(n)-4.0),freq,freq2
  if(line(1)(1:6).eq.'      ') line(1)(1:1)=char(0)

  return
end subroutine jtmsk_decode
