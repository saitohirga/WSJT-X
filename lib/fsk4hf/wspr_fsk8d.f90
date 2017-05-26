program wspr_fsk8d

! WSPR-LF is a potential WSPR-like mode intended for use at LF and MF.
! This version uses 4-minute T/R sequences, an LDPC (300,60) code,
! 8-FSK modulation, and noncoherent demodulation.  This decoder reads
! data from *.wav files.

! Reception and Demodulation algorithm:
!   1. Compute coarse spectrum; find fc1 = approx carrier freq
!   2. Mix from fc1 to 0; LPF at +/- 0.75*R
!   3. Find two 7x7 Costas arrays to get xdt and fc2
!   4. Mix from fc2 to 0, compute aligned symbol spectra
!   5. Get soft bits from symbol spectra

! Still to do: find and decode more than one signal in the specified passband.

  include 'wspr_fsk8_params.f90'
  character arg*8,message*22,cbits*50,infile*80,fname*16,datetime*11
  character*120 data_dir
  complex csync(0:N7-1)                 !Sync symbols for Costas 7x7 array
  complex c1(0:2*N7-1)
  complex c2(0:2*N7-1)
  complex c(0:NMAXD-1)                     !Complex waveform
  real*8 fMHz
  real rxdata(3*ND),llr(3*ND)           !Soft symbols
  real a(5)                             !For twkfreq1
  real s(0:NH2,NN)
  real savg(0:NH2)
  real ss(0:N7)
  real ss0(0:N7)
  real ps(0:7)
  integer ihdr(11)
  integer*2 iwave(NMAX)                 !Generated full-length waveform  
  integer*1 idat(7)
  integer*1 decoded(KK),apmask(3*ND),cw(3*ND)
  integer icos7(0:6)
  data icos7/2,5,6,0,4,1,3/             !Costas 7x7 tone pattern

  nargs=iargc()
  if(nargs.lt.7) then
     print*,'Usage:   wspr_fsk8d -d db -f fMHz -a data_dir file1 [file2 ...]'
     go to 999
  endif
  call getarg(1,arg)
  if(arg(1:3).ne.'-d ') go to 999
  call getarg(2,arg)
  read(arg,*) degrade
  rxbw=3000.

  call getarg(3,arg)
  if(arg(1:3).ne.'-f ') go to 999
  call getarg(4,arg)
  read(arg,*) fMHz

  call getarg(5,arg)
  if(arg(1:3).ne.'-a ') go to 999
  call getarg(6,data_dir)
  
  open(13,file=trim(data_dir)//'/ALL_WSPR.TXT',status='unknown',   &
       position='append')

  twopi=8.0*atan(1.0)
  fs=NSPS*12000.0/NSPS0                  !Sample rate after downsampling (Hz)
  dt=1.0/fs                              !Sample interval (s)
  ts=NSPS*dt                             !Symbol duration (s)
  baud=1.0/ts                            !Keying rate (Hz)
  txt=NZ*dt                              !Transmission length (s)

  phi=0.
  k=-1
  do j=0,6
     dphi=twopi*baud*icos7(j)*dt
     do i=1,NSPS
        phi=phi+dphi
        if(phi.gt.twopi) phi=phi-twopi
        k=k+1
        csync(k)=cmplx(cos(phi),sin(phi))
     enddo
  enddo

  do ifile=7,nargs
     call getarg(ifile,infile)
     open(10,file=infile,status='old',access='stream')
     j1=index(infile,'.c4')
     j2=index(infile,'.wav')
     if(j1.gt.0) then
       read(10,end=999) fname,ntrmin,fMHz,c(0:NZ-1)
       read(fname(8:11),*) nutc
       write(datetime,'(i11)') nutc
     else if(j2.gt.0) then
       read(10,end=999) ihdr,iwave
       read(infile(j2-4:j2-1),*) nutc
       datetime=infile(j2-11:j2-1)
       if(degrade.gt.0.0) call degrade_snr(iwave,NMAX,degrade,rxbw)
       call wspr_fsk8_downsample(iwave,c)
     else
       print*,'Wrong file format?'
       go to 999
     endif
     close(10)
     pmax=0.
     df1=fs/(2*N7)
     ia=nint(100.0/df1)
     ib=nint(150.0/df1)
     ipk=0
     jpk=0
! Get xdt and f0 from the sync arrays
     do j0=0,1000,50
        j0b=j0+107*NSPS
        c1(0:N7-1)=c(j0:j0+N7-1)*conjg(csync)
        c1(N7:)=0.
        c2(0:N7-1)=c(j0b:j0b+N7-1)*conjg(csync)
        c2(N7:)=0.
        call four2a(c1,2*N7,1,-1,1)
        call four2a(c2,2*N7,1,-1,1)
        do i=0,N7
           p=1.e-9*(real(c1(i))**2 + aimag(c1(i))**2 +                        &
                real(c2(i))**2 + aimag(c2(i))**2)
           ss(i)=p
        enddo
        do i=ia,ib
           p=ss(i)
           if(p.gt.pmax) then
              pmax=p
              ipk=i
              jpk=j0
           endif
        enddo
        if(jpk.eq.j0) ss0=ss
     enddo
     f0=ipk*df1
     xdt=jpk*dt - 1.0
     
     sp3n=(ss0(ipk-1)+ss0(ipk)+ss0(ipk+1))      !Sig + 3*noise
     call pctile(ss0,N7,45,base)
     psig=sp3n-3*base                           !Sig only
     pnoise=(2500.0/df1)*base                   !Noise in 2500 Hz
     xsnr=db(psig/pnoise)                       !SNR from sync tones

     if(jpk.ge.0) c(0:NMAXD-1-jpk)=c(jpk:NMAXD-1)

     a(1)=-f0
     a(2:5)=0.
     call twkfreq1(c,NZ,fs,a,c)              !Mix from f0 down to 0
     call spec8(c,s,savg)                    !Get symbol spectra

     do j=1,ND
        k=j+7
        ps=s(0:7,k)
        !        ps=sqrt(ps)                                !### ??? ###
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
     s0=0.84
     llr=2.0*rxdata/(s0*s0)
     apmask=0
     max_iterations=40
     ifer=0
     call bpdecode300(llr,apmask,max_iterations,decoded,niterations,cw)
     if(niterations.lt.0) call osd300(llr,4,decoded,niterations,cw)
     nbadcrc=0
     if(niterations.ge.0) call chkcrc10(decoded,nbadcrc)
     if(niterations.lt.0 .or. nbadcrc.ne.0) ifer=1
     nsnr=nint(xsnr)
!     freq=fMHz + 1.d-6*f0
     freq=1.d-6*(f0+1500)
     nfdot=0
     message='                      '
     if(ifer.eq.0) then
        write(cbits,1100) decoded(1:50)
1100    format(50i1)
        read(cbits,1102) idat
1102    format(6b8,b2)
        idat(7)=ishft(idat(7),6)
        call wqdecode(idat,message,itype)
        write(*,1112) datetime(8:11),nsnr,xdt,freq,nfdot,message
1112    format(a4,i4,f5.1,f11.6,i3,2x,a22)
     endif
     write(13,1110) datetime,0,nsnr,xdt,freq,message,nfdot
1110 format(a11,2i4,f6.2,f12.7,2x,a22,i3)
  enddo                                   ! ifile loop
  write(*,1120)
1120 format("<DecodeFinished>")

999 end program wspr_fsk8d

