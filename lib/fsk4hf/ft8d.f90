program ft8d

! Decode FT8 data read from *.wav files.

! FT8 is a potential mode intended for use at 6m (and maybe HF).  It uses an
! LDPC (174,87) code, 8-FSK modulation, and 15 second T/R sequences.  Otherwise
! should behave like JT65 and JT9 as used on HF bands, except that QSOs are
! 4 x faster.

! Reception and Demodulation algorithm:
!   ... tbd ...

  include 'ft8_params.f90'
  parameter(NRECENT=10)
  character*12 recent_calls(NRECENT),arg
  character message*22,infile*80,datetime*13
  real s(NH1,NHSYM)
  real s1(0:7,ND)
  real ps(0:7)
  real rxdata(3*ND),llr(3*ND)               !Soft symbols
  integer ihdr(11)
  integer*2 iwave(NMAX)                 !Generated full-length waveform  
!  integer*1 idat(7)
  integer*1 decoded(KK),apmask(3*ND),cw(3*ND)
  integer*8 count0,count1,clkfreq
  
  nargs=iargc()
  if(nargs.lt.3) then
     print*,'Usage:   ft8d MaxIt Norder file1 [file2 ...]'
     print*,'Example  ft8d   40     2   *.wav'
     go to 999
  endif
  call getarg(1,arg)
  read(arg,*) max_iterations
  call getarg(2,arg)
  read(arg,*) norder
  nfiles=nargs-2

  twopi=8.0*atan(1.0)
  fs=12000.0                             !Sample rate
  dt=1.0/fs                              !Sample interval (s)
  tt=NSPS*dt                             !Duration of "itone" symbols (s)
  ts=2*NSPS*dt                           !Duration of OQPSK symbols (s)
  baud=1.0/tt                            !Keying rate (baud)
  txt=NZ*dt                              !Transmission length (s)
  nsync=0
  ngood=0
  nbad=0
  tsec=0.

  do ifile=1,nfiles
     call getarg(ifile+2,infile)
     open(10,file=infile,status='old',access='stream')
     read(10,end=999) ihdr,iwave
     close(10)
     j2=index(infile,'.wav')
     read(infile(j2-6:j2-1),*) nutc
     datetime=infile(j2-13:j2-1)
     call system_clock(count0,clkfreq)

!     call ft8filbig(iwave,NN*NSPS)
     call sync8(iwave,xdt,f1,s)

     xsnr=0.
     tstep=0.5*NSPS/12000.0
     df=12000.0/NFFT1
     i0=nint(f1/df)
     j0=nint(xdt/tstep)
     fac=20.0/maxval(s)
     s=fac*s

     j=0
     ia=i0
     ib=i0+14
     do k=1,NN
        if(k.le.7) cycle
        if(k.ge.37 .and. k.le.43) cycle
        if(k.gt.72) cycle
        n=j0+2*(k-1)+1
        if(n.lt.1) cycle
        j=j+1
        s1(0:7,j)=s(ia:ib:2,n)
     enddo

     do j=1,ND
        ps=s1(0:7,j)
        ps=log(ps)
        r1=max(ps(1),ps(3),ps(5),ps(7))-max(ps(0),ps(2),ps(4),ps(6))
        r2=max(ps(2),ps(3),ps(6),ps(7))-max(ps(0),ps(1),ps(4),ps(5))
        r4=max(ps(4),ps(5),ps(6),ps(7))-max(ps(0),ps(1),ps(2),ps(3))
        rxdata(3*j-2)=r4
        rxdata(3*j-1)=r2
        rxdata(3*j)=r1
     enddo
     rxav=sum(rxdata)/ND
     rx2av=sum(rxdata*rxdata)/ND
     rxsig=sqrt(rx2av-rxav*rxav)
     rxdata=rxdata/rxsig
     ss=0.84
     llr=2.0*rxdata/(ss*ss)
     apmask=0
     call bpdecode174(llr,apmask,max_iterations,decoded,niterations)
     if(niterations.lt.0) call osd174(llr,norder,decoded,nharderrors,cw)
     nbadcrc=0
     call chkcrc12a(decoded,nbadcrc)

     message='                      '
     if(nbadcrc.eq.0) then
        call extractmessage174(decoded,message,ncrcflag,recent_calls,nrecent)
     endif
     nsnr=nint(xsnr)
     write(13,1110) datetime,0,nsnr,xdt,f1,niterations,nharderrors,message
1110 format(a13,2i4,f6.2,f7.1,2i4,2x,a22)
     write(*,1112) datetime(8:13),nsnr,xdt,nint(f1),message
1112 format(a6,i4,f5.1,i6,2x,a22)
     if(abs(xdt).le.0.1 .or. abs(f1-1500).le.2.93) nsync=nsync+1
     if(message.eq.'K1ABC W9XYZ EN37      ') ngood=ngood+1
     if(message.ne.'K1ABC W9XYZ EN37      ' .and.                      &
        message.ne.'                      ') nbad=nbad+1
     call system_clock(count1,clkfreq)
     tsec=tsec+float(count1-count0)/float(clkfreq)
  enddo   ! ifile loop

  write(*,1100) max_iterations,norder,float(nsync)/nfiles,float(ngood)/nfiles,  &
       float(nbad)/nfiles,tsec/nfiles
1100 format(2i5,3f8.4,f9.3)

999 end program ft8d
