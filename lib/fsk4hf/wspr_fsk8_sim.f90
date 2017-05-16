program wspr_fsk8_sim

! Generate simulated data for a 4-minute "WSPR-LF" mode using 8-FSK.
! Output is saved to a *.wav file.

  use wavhdr
  include 'wspr_fsk8_params.f90'         !Set various constants
  parameter (NMAX=300*12000)
  type(hdr) h                            !Header for .wav file
  character arg*12,fname*16
  character msg*22,msgsent*22
  integer itone(NN)
  integer*2 iwave(NMAX)                  !Generated full-length waveform  

! Get command-line argument(s)
  nargs=iargc()
  if(nargs.ne.5) then
     print*,'Usage:   wspr_fsk8_sim "message"        f0   DT nfiles snr'
     print*,'Example: wspr_fsk8_sim "K1ABC FN42 30" 1640 0.0   10   -33'
     go to 999
  endif
  call getarg(1,msg)                     !Message to be transmitted
  call getarg(2,arg)
  read(arg,*) f0                         !Freq relative to WSPR-band center (Hz)
  call getarg(3,arg)
  read(arg,*) xdt                        !Time offset from nominal (s)
  call getarg(4,arg)
  read(arg,*) nfiles                     !Number of files
  call getarg(5,arg)
  read(arg,*) snrdb                      !SNR_2500

  twopi=8.0*atan(1.0)
  fs=12000.0/NDOWN                       !Sample rate after downsampling
  dt=1.0/fs                              !Sample interval (s)
  tt=NSPS*dt                             !Duration of symbols (s)
  baud=1.0/tt                            !Keying rate
  bw=8*baud
  txt=NZ*dt                              !Transmission length (s)
  bandwidth_ratio=2500.0/(fs/2.0)
  sig=sqrt(bandwidth_ratio) * 10.0**(0.05*snrdb)
  if(snrdb.gt.90.0) sig=1.0
  txt=NN*NSPS0/12000.0

  call genwspr_fsk8(msg,msgsent,itone)       !Encode the message, get itone
  write(*,1000) f0,xdt,txt,snrdb,bw,msgsent
1000 format('f0:',f9.3,'   DT:',f6.2,'   TxT:',f6.1,'   SNR:',f6.1,    &
          '  BW:',f4.1,2x,a22)

  do ifile=1,nfiles
     call wspr_fsk8_wav(baud,xdt,f0,itone,snrdb,iwave)
     h=default_header(12000,NMAX)
     write(fname,1102) ifile
1102 format('000000_',i4.4,'.wav')
     open(10,file=fname,status='unknown',access='stream')
     write(10) h,iwave                !Save to *.wav file
     close(10)
     write(*,1110) ifile,xdt,f0,snrdb,fname
1110 format(i4,f7.2,f8.2,f7.1,2x,a16)
  enddo
       
999 end program wspr_fsk8_sim

  include 'wspr_fsk8_wav.f90'
  
