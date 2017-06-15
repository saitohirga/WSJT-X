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
  character*12 recent_calls(NRECENT)
  character message*22,infile*80,datetime*11
  real s(NH1,NHSYM)
  real s1(0:7,ND)
  real ps(0:7)
  real rxdata(3*ND),llr(3*ND)               !Soft symbols
  integer ihdr(11)
  integer*2 iwave(NMAX)                 !Generated full-length waveform  
!  integer*1 idat(7)
  integer*1 decoded(KK),apmask(ND),cw(ND)

  nargs=iargc()
  if(nargs.lt.1) then
     print*,'Usage:   ft8d file1 [file2 ...]'
     go to 999
  endif

  twopi=8.0*atan(1.0)
  fs=12000.0                             !Sample rate
  dt=1.0/fs                              !Sample interval (s)
  tt=NSPS*dt                             !Duration of "itone" symbols (s)
  ts=2*NSPS*dt                           !Duration of OQPSK symbols (s)
  baud=1.0/tt                            !Keying rate (baud)
  txt=NZ*dt                              !Transmission length (s)

  do ifile=1,nargs
     call getarg(ifile,infile)
     open(10,file=infile,status='old',access='stream')
     read(10,end=999) ihdr,iwave
     close(10)
     j2=index(infile,'.wav')
     read(infile(j2-4:j2-1),*) nutc
     datetime=infile(j2-11:j2-1)
     call sync8(iwave,xdt,f1,s)

     xsnr=0.
     tstep=0.5*NSPS/12000.0
     df=12000.0/NFFT1
     i0=nint(f1/df)
     j0=nint((xdt+0.5)/tstep)
     fac=20.0/maxval(s)
     s=fac*s

     j=0
     ia=i0
     ib=i0+14
     do k=1,NN
        n=j0+2*(k-1)+1
        if(k.le.7) cycle
        if(k.ge.37 .and. k.le.43) cycle
        if(k.gt.72) cycle
        j=j+1
        s1(0:7,j)=s(ia:ib:2,n)
     enddo

     do j=1,ND
        ps=s1(0:7,j)
!        ps=log(ps)
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
     max_iterations=40
     ifer=0
     call bpdecode174(llr,apmask,max_iterations,decoded,niterations)
     if(niterations.lt.0) call osd174(llr,2,decoded,niterations,cw)
     nbadcrc=0
     if(niterations.ge.0) call chkcrc12a(decoded,nbadcrc)
     if(niterations.lt.0 .or. nbadcrc.ne.0) ifer=1

     message='                      '
     if(ifer.eq.0) then
        call extractmessage174(decoded,message,ncrcflag,recent_calls,nrecent)
        nsnr=nint(xsnr)
        nfdot=0
        write(13,1110) datetime,0,nsnr,xdt,freq,message,nfdot
1110    format(a11,2i4,f6.2,f12.7,2x,a22,i3)
        write(*,1112) datetime(8:11),nsnr,xdt,nint(f1),message
1112    format(a4,i4,f5.1,i6,2x,a22)
     endif
  enddo                                   ! ifile loop
!  write(*,1120)
!1120 format("<DecodeFinished>")

999 end program ft8d
