program wspr5d

! Decode WSPR-LF data read from *.c5 or *.wav files.

! WSPR-LF is a potential WSPR-like mode intended for use at LF and MF.
! It uses an LDPC (300,60) code, OQPSK modulation, and 5 minute T/R sequences.

! Reception and Demodulation algorithm:
!   1. Compute coarse spectrum; find fc1 = approx carrier freq
!   2. Mix from fc1 to 0; LPF at +/- 0.75*R
!   3. Square, FFT; find peaks near -R/2 and +R/2 to get fc2
!   4. Mix from fc2 to 0
!   5. Fit cb13 (central part of csync) to c -> lag, phase
!   6. Fit complex ploynomial for channel equalization
!   7. Get soft bits from equalized data

! Still to do: find and decode more than one signal in the specified passband.

  include 'wsprlf_params.f90'
  parameter (NMAX=300*12000)
  character arg*8,message*22,cbits*50,infile*80,fname*16,datetime*11
  character*120 data_dir
  complex csync(0:NZ-1)                 !Sync symbols only, from cbb
  complex c(0:NZ-1)                     !Complex waveform
  complex c1(0:NZ-1)                    !Complex waveform
  complex zz(NS+ND)                     !Complex symbol values (intermediate)
  complex z
  real*8 fMHz
  real rxdata(ND),llr(ND)               !Soft symbols
  real pp(2*NSPS)                       !Shaped pulse for OQPSK
  real a(5)                             !For twkfreq1
  real aa(20),bb(20)                    !Fitted polyco's
  real fpks(20)
  integer id(NS+ND)                     !NRZ values (+/-1) for Sync and Data
  integer ierror(NS+ND)
  integer isync(48)                     !Long sync vector
  integer ib13(13)                      !Barker 13 code
  integer ihdr(11)
  integer*8 n8
  integer*2 iwave(NMAX)                 !Generated full-length waveform  
  integer*1 idat(7)
  integer*1 decoded(KK),apmask(ND),cw(ND)
  data ib13/1,1,1,1,1,-1,-1,1,1,-1,1,-1,1/

  nargs=iargc()
  if(nargs.lt.2) then
     print*,'Usage:   wspr5d [-a <data_dir>] [-f fMHz] file1 [file2 ...]'
     go to 999
  endif
  iarg=1
  data_dir="."
  call getarg(iarg,arg)
  if(arg(1:2).eq.'-a') then
     call getarg(iarg+1,data_dir)
     iarg=iarg+2
  endif
  call getarg(iarg,arg)
  if(arg(1:2).eq.'-f') then
     call getarg(iarg+1,arg)
     read(arg,*) fMHz
     iarg=iarg+2
  endif
  
  open(13,file=trim(data_dir)//'/ALL_WSPR.TXT',status='unknown',   &
       position='append')
  maxn=8                                 !Default value
  twopi=8.0*atan(1.0)
  fs=NSPS*12000.0/NSPS0                  !Sample rate
  dt=1.0/fs                              !Sample interval (s)
  tt=NSPS*dt                             !Duration of "itone" symbols (s)
  ts=2*NSPS*dt                           !Duration of OQPSK symbols (s)
  baud=1.0/tt                            !Keying rate for "itone" symbols (baud)
  txt=NZ*dt                              !Transmission length (s)

  do i=1,N2                              !Half-sine pulse shape
     pp(i)=sin(0.5*(i-1)*twopi/(2*NSPS))
  enddo
  n8=z'cbf089223a51'
  do i=1,48
     isync(i)=-1
     if(iand(n8,1).eq.1) isync(i)=1
     n8=n8/2
  enddo

! Define array id() for sync symbols
  id=0
  do j=1,48                             !First group of 48
     id(2*j-1)=2*isync(j)
  enddo
  do j=1,13                             !Barker 13 code
     id(j+96)=2*ib13(j)
  enddo
  do j=1,48                             !Second group of 48
     id(2*j+109)=2*isync(j)
  enddo

  csync=0.
  do j=1,205
     if(abs(id(j)).eq.2) then
        ia=nint((j-0.5)*N2)
        ib=ia+N2-1
        csync(ia:ib)=pp*id(j)/abs(id(j))
     endif
  enddo

  do ifile=iarg,nargs
     call getarg(ifile,infile)
     open(10,file=infile,status='old',access='stream')
     j1=index(infile,'.c5')
     j2=index(infile,'.wav')
     if(j1.gt.0) then
        read(10,end=999) fname,ntrmin,fMHz,c
        read(fname(8:11),*) nutc
        write(datetime,'(i11)') nutc
     else if(j2.gt.0) then
        read(10,end=999) ihdr,iwave
        read(infile(j2-4:j2-1),*) nutc
        datetime=infile(j2-11:j2-1)
        call wspr5_downsample(iwave,c)
     else
        print*,'Wrong file format?'
        go to 999
     endif
     close(10)
     fa=100.0
     fb=150.0
     call getfc1w(c,fs,fa,fb,fc1,xsnr)         !First approx for freq
     npeaks=20
     call getfc2w(c,csync,npeaks,fs,fc1,fpks)      !Refined freq

     a(1)=-fc1
     a(2:5)=0.
     call twkfreq1(c,NZ,fs,a,c)       !Mix c down by fc1+fc2

! Find time offset xdt
     amax=0.
     jpk=0
     iaa=0
     ibb=NZ-1
     jmax=1260
     do j=-jmax,jmax,NSPS/8
        ia=j
        ib=NZ-1+j
        if(ia.lt.0) then
           ia=0
           iaa=-j
        else
           iaa=0
        endif
        if(ib.gt.NZ-1) then
           ib=NZ-1
           ibb=NZ-1-j
        endif
        z=sum(c(ia:ib)*conjg(csync(iaa:ibb)))
write(51,*) j/fs,real(z),imag(z)
        if(abs(z).gt.amax) then
           amax=abs(z)
           jpk=j
        endif
     enddo
     xdt=jpk/fs
xdt=1.0
jpk=fs*xdt
     do i=0,NZ-1
        j=i+jpk
        if(j.ge.0 .and. j.lt.NZ) c1(i)=c(j)
     enddo

     nterms=maxn
     do itry=1,npeaks
        nhard0=0
        nhardsync0=0
        ifer=1
        a(1)=-fpks(itry)
        a(2:5)=0.
        call twkfreq1(c1,NZ,fs,a,c)       !Mix c1 into c
        call cpolyfitw(c,pp,id,maxn,aa,bb,zz,nhs)
        call msksoftsymw(zz,aa,bb,id,nterms,ierror,rxdata,nhard0,nhardsync0)
        if(nhardsync0.gt.35) cycle
        rxav=sum(rxdata)/ND
        rx2av=sum(rxdata*rxdata)/ND
        rxsig=sqrt(rx2av-rxav*rxav)
        rxdata=rxdata/rxsig
        ss=0.84
        llr=2.0*rxdata/(ss*ss)
        apmask=0
        max_iterations=40
        ifer=0
        call bpdecode300(llr,apmask,max_iterations,decoded,niterations,cw)
        if(niterations.lt.0) call osd300(llr,4,decoded,niterations,cw)
        nbadcrc=0
        if(niterations.ge.0) call chkcrc10(decoded,nbadcrc)
        if(niterations.lt.0 .or. nbadcrc.ne.0) ifer=1
        if(ifer.eq.0) exit
     enddo                                !Freq dither loop
     message='                      '
     if(ifer.eq.0) then
        write(cbits,1100) decoded(1:50)
1100    format(50i1)
        read(cbits,1102) idat
1102    format(6b8,b2)
        idat(7)=ishft(idat(7),6)
        call wqdecode(idat,message,itype)
        nsnr=nint(xsnr)
!        freq=fMHz + 1.d-6*(fc1+fc2)
        freq=fMHz + 1.d-6*(fc1+fpks(itry))
        nfdot=0
        write(13,1110) datetime,0,nsnr,xdt,freq,message,nfdot
1110    format(a11,2i4,f6.2,f12.7,2x,a22,i3)
        write(*,1112) datetime(8:11),nsnr,xdt,freq,nfdot,message,itry
1112    format(a4,i4,f5.1,f11.6,i3,2x,a22,i4)
     endif
  enddo                                   ! ifile loop
  write(*,1120)
1120 format("<DecodeFinished>")

999 end program wspr5d
