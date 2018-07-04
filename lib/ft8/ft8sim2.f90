program ft8sim2

! Generate simulated "type 2" ft8 files
! Output is saved to a *.wav file.

  use wavhdr
  include 'ft8_params.f90'               !Set various constants
  parameter (NWAVE=NN*NSPS)
  type(hdr) h                            !Header for .wav file
  character arg*12,fname*17
  character msg37*37,msgsent37*37,msg40*40
  character c77*77
  character*6 mygrid6
  logical bcontest
  complex c0(0:NMAX-1)
  complex c(0:NMAX-1)
  real wave(NMAX)
  integer itone(NN)
  integer*1 msgbits(77)
  integer*2 iwave(NMAX)                  !Generated full-length waveform
  data mygrid6/'EM48  '/

! Get command-line argument(s)
  nargs=iargc()
  if(nargs.ne.8) then
     print*,'Usage:    ft8sim "message"         nsig|f0  DT fdop del width nfiles snr'
     print*,'Examples: ft8sim "K1ABC W9XYZ EN37" 1500.0 0.0  0.1 1.0   0     10   -18'
     print*,'          ft8sim "K1ABC W9XYZ EN37"   10   0.0  0.1 1.0  25     10   -18'
     print*,'          ft8sim "K1ABC W9XYZ EN37"   25   0.0  0.1 1.0  25     10   -18'
     print*,'          ft8sim "K1ABC RR73; W9XYZ <KH1/KH7Z> -11" 300 0 0 0 25 1 -10'
     print*,'Make nfiles negative to invoke 72-bit contest mode.'
     go to 999
  endif
  call getarg(1,msg37)                   !Message to be transmitted
  call getarg(2,arg)
  read(arg,*) f0                         !Frequency (only used for single-signal)
  call getarg(3,arg)
  read(arg,*) xdt                        !Time offset from nominal (s)
  call getarg(4,arg)
  read(arg,*) fspread                    !Watterson frequency spread (Hz)
  call getarg(5,arg)
  read(arg,*) delay                      !Watterson delay (ms)
  call getarg(6,arg)
  read(arg,*) width                      !Filter transition width (Hz)
  call getarg(7,arg)
  read(arg,*) nfiles                     !Number of files
  call getarg(8,arg)
  read(arg,*) snrdb                      !SNR_2500

  nsig=1
  if(f0.lt.100.0) then
     nsig=f0
     f0=1500
  endif

  bcontest=nfiles.lt.0
  nfiles=abs(nfiles)
  twopi=8.0*atan(1.0)
  fs=12000.0                             !Sample rate (Hz)
  dt=1.0/fs                              !Sample interval (s)
  tt=NSPS*dt                             !Duration of symbols (s)
  baud=1.0/tt                            !Keying rate (baud)
  bw=8*baud                              !Occupied bandwidth (Hz)
  txt=NZ*dt                              !Transmission length (s)
  bandwidth_ratio=2500.0/(fs/2.0)
  sig=sqrt(2*bandwidth_ratio) * 10.0**(0.05*snrdb)
  if(snrdb.gt.90.0) sig=1.0
  txt=NN*NSPS/12000.0

! Source-encode, then get itone()
  call pack77(msg37,i3,n3,c77)
  call unpack77(c77,msgsent37)
  call genft8_174_91(msg37,mygrid6,bcontest,i3,n3,msgsent37,msgbits,itone)
  write(*,1000) f0,xdt,txt,snrdb,bw,msgsent37
1000 format('f0:',f9.3,'   DT:',f6.2,'   TxT:',f6.1,'   SNR:',f6.1,    &
       '  BW:',f4.1,2x,a37)
  
  write(*,'(a23,a37,i1,a1,i1)') 'New Style FT8 Message: ',msgsent37,i3,'.',n3
  write(*,'(a14)') 'Message bits: '
  write(*,'(77i1)') msgbits
  write(*,'(a17)') 'Channel symbols: '
  write(*,'(79i1)') itone

  call sgran()

  msg0=msg
  do ifile=1,nfiles
     k=nint((xdt+0.5)/dt)
     ia=k
     phi=0.0
     do j=1,NN                             !Generate complex waveform
        dphi=twopi*(f0*dt+itone(j)/real(NSPS))
        do i=1,NSPS
           if(k.ge.0 .and. k.lt.NMAX) c0(k)=cmplx(cos(phi),sin(phi))
           k=k+1
           phi=mod(phi+dphi,twopi)
        enddo
     enddo
     if(fspread.ne.0.0 .or. delay.ne.0.0) call watterson(c0,NMAX,fs,delay,fspread)
     c=c+sig*c0
  enddo
  ib=k
  wave=real(c)
  peak=maxval(abs(wave(ia:ib)))
  rms=sqrt(dot_product(wave(ia:ib),wave(ia:ib))/NWAVE)
  nslots=1
  if(width.gt.0.0) call filt8(f0,nslots,width,wave)
   
  if(snrdb.lt.90) then
     do i=1,NMAX                   !Add gaussian noise at specified SNR
        xnoise=gran()
        wave(i)=wave(i) + xnoise
     enddo
  endif

  fac=32767.0
  rms=100.0
  if(snrdb.ge.90.0) iwave(1:NMAX)=nint(fac*wave)
  if(snrdb.lt.90.0) iwave(1:NMAX)=nint(rms*wave)

  h=default_header(12000,NMAX)
  write(fname,1102) ifile
1102 format('000000_',i6.6,'.wav')
  open(10,file=fname,status='unknown',access='stream')
  write(10) h,iwave                !Save to *.wav file
  close(10)
  write(*,1110) ifile,xdt,f0,snrdb,fname
1110 format(i4,f7.2,f8.2,f7.1,2x,a17)
       
999 end program ft8sim2
