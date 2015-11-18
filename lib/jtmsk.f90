subroutine jtmsk(id2,narg,line)

! Decoder for JTMSK

  parameter (NMAX=30*12000)
  parameter (NFFTMAX=512*1024)
  parameter (NSPM=1404)                !Samples per JTMSK message
  integer*2 id2(0:NMAX)                !Raw i*2 data, up to T/R = 30 s
  real d(0:NMAX)                       !Raw r*4 data
  real ty(703)
  real yellow(703)
!  real spk2(20)
!  real fpk2(20)
!  integer jpk2(20)
  complex c(NFFTMAX)                   !Complex (analytic) data
  complex cdat(24000)                  !Short segments, up to 2 s
  complex cdat2(24000)
  integer narg(0:11)                   !Arguments passed from calling pgm
  character*22 msg,msg0                !Decoded message
  character*80 line(100)               !Decodes passed back to caller
  common/tracer/ limtrace,lu

  limtrace=-1
  lu=12
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

  nsnr0=-99
  nline=0
  line(1:100)(1:1)=char(0)
  msg0='                      '
  msg=msg0

  d(0:npts-1)=id2(0:npts-1)
  rms=sqrt(dot_product(d(0:npts-1),d(0:npts-1))/npts)
  d(0:npts-1)=d(0:npts-1)/rms
  call timer('mskdt   ',0)
  call mskdt(d,npts,ty,yellow,nyel)
  nyel=min(nyel,5)
  call timer('mskdt   ',1)

  n=log(float(npts))/log(2.0) + 1.0
  nfft=min(2**n,1024*1024)
  call timer('analytic',0)
  call analytic(d,npts,nfft,c)         !Convert to analytic signal
  call timer('analytic',1)

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
!     call msksync(cdat,iz,jpk2,fpk2,spk2)
!     call softmsk(cdat,iz,jpk2,fpk2,spk2)

     do itry=1,21
        idf1=(itry/2) * 50
        if(mod(itry,2).eq.1) idf1=-idf1
        if(abs(idf1).gt.ntol) exit
        fpk=idf1 + nrxfreq
        call timer('tweak1  ',0)
        call tweak1(cdat2,iz,1500.0-fpk,cdat)
        call timer('tweak1  ',1)

        call timer('syncmsk ',0)
        call syncmsk(cdat,iz,jpk,ipk,idf,rmax,snr,metric,msg)
        call timer('syncmsk ',1)
        freq=fpk+idf
!        write(72,4001) jpk,idf,nint(freq),rmax,snr,msg
!4001    format(3i6,2f9.2,2x,a22)
        if(metric.eq.-9999) cycle             !No output if no significant sync
        t0=(ia+jpk)/12000.0
        nsnr=nint(yellow(n)-2.0)
        if(msg.ne.'                      ') then
           if(msg.ne.msg0) then
              nline=nline+1
              nsnr0=-99
           endif
           if(nsnr.gt.nsnr0) then
              call rectify_msk(cdat2(jpk:jpk+NSPM-1),msg,freq2)
              write(line(nline),1020) nutc,nsnr,t0,nint(freq2),msg
1020          format(i6.6,i4,f5.1,i5,' & ',a22)
              nsnr0=nsnr
              go to 900
           endif
           msg0=msg
           if(nline.ge.maxlines) go to 900
        endif
     enddo
  enddo

900 if(line(1)(1:6).eq.'      ') line(1)(1:1)=char(0)

  return
end subroutine jtmsk
