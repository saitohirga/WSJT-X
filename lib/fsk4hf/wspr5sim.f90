program wspr5sim

! Generate simulated data for a 5-minute "WSPR-LF" mode.  Output is saved 
! to a *.c5 or *.wav file.

  use wavhdr
  include 'wsprlf_params.f90'            !Set various constants
  parameter (NMAX=300*12000)
  type(hdr) h                            !Header for .wav file
  character arg*12,fname*16
  character msg*22,msgsent*22
  complex c0(0:NZ-1)
  complex c(0:NZ-1)
  real*8 fMHz
  integer itone(NN)
  integer*2 iwave(NMAX)                  !Generated full-length waveform  

! Get command-line argument(s)
  nargs=iargc()
  if(nargs.ne.6) then
     print*,'Usage:   wspr5sim "message"       f0  DT nwav nfiles snr'
     print*,'Example: wspr5sim "K1ABC FN42 30" 50 0.0  0     10   -33'
     go to 999
  endif
  call getarg(1,msg)                     !Message to be transmitted
  call getarg(2,arg)
  read(arg,*) f0                         !Freq relative to WSPR-band center (Hz)
  call getarg(3,arg)
  read(arg,*) xdt                        !Time offset from nominal (s)
  call getarg(4,arg)
  read(arg,*) nwav                       !1 for *.wav file, 0 for *.c5 file
  call getarg(5,arg)
  read(arg,*) nfiles                     !Number of files
  call getarg(6,arg)
  read(arg,*) snrdb                      !SNR_2500

  twopi=8.0*atan(1.0)
  fs=12000.0/NDOWN                       !Sample rate
  dt=1.0/fs                              !Sample interval (s)
  tt=NSPS*dt                             !Duration of "itone" symbols (s)
  ts=2*NSPS*dt                           !Duration of OQPSK symbols (s)
  baud=1.0/tt                            !Keying rate for "itone" symbols (baud)
  txt=NZ*dt                              !Transmission length (s)
  bandwidth_ratio=2500.0/(fs/2.0)
  sig=sqrt(bandwidth_ratio) * 10.0**(0.05*snrdb)
  if(snrdb.gt.90.0) sig=1.0
  txt=NN*NSPS0/12000.0

  call genwspr5(msg,ichk,msgsent,itone,itype)  !Encode the message, get itone
  write(*,1000) f0,xdt,txt,snrdb,nfiles,msgsent
1000 format('f0:',f9.3,'   DT:',f6.2,'   txt:',f6.1,'   SNR:',f6.1,    &
          '  nfiles:',i3,2x,a22)

  dphi0=twopi*(f0-0.25*baud)*dt
  dphi1=twopi*(f0+0.25*baud)*dt
  phi=0.0
  c0=0.
  k=-1 + nint(xdt/dt)
  do j=1,NN                              !Generate OQPSK waveform from itone
     dphi=dphi0
     if(itone(j).eq.1) dphi=dphi1
     if(k.eq.0) phi=-dphi
     do i=1,NSPS
        k=k+1
        phi=phi+dphi
        if(phi.gt.twopi) phi=phi-twopi
        xphi=phi
        if(k.ge.0 .and. k.lt.NZ) c0(k)=cmplx(cos(xphi),sin(xphi))
     enddo
  enddo
  c0=sig*c0                              !Scale to requested sig level

  do ifile=1,nfiles
     if(nwav.eq.0) then
        if(snrdb.lt.90) then
           do i=0,NZ-1                   !Add gaussian noise at specified SNR
              xnoise=gran()
              ynoise=gran()
              c(i)=c0(i) + cmplx(xnoise,ynoise)
           enddo
        endif
        write(fname,1100) ifile
1100    format('000000_',i4.4,'.c5')
        open(10,file=fname,status='unknown',access='stream')
        fMHz=10.1387d0
        nmin=5
        write(10) fname,nmin,fMHz,c      !Save to *.c5 file
        close(10)
     else
        call wspr5_wav(baud,xdt,f0,itone,snrdb,iwave)
        h=default_header(12000,NMAX)
        write(fname,1102) ifile
1102    format('000000_',i4.4,'.wav')
        open(10,file=fname,status='unknown',access='stream')
        write(10) h,iwave                !Save to *.wav file
        close(10)
     endif
     write(*,1110) ifile,xdt,f0,snrdb,fname
1110 format(i4,f7.2,f8.2,f7.1,2x,a16)
  enddo
       
999 end program wspr5sim
