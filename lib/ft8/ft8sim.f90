program ft8sim

! Generate simulated data for a 15-second HF/6m mode using 8-FSK.
! Output is saved to a *.wav file.

  use wavhdr
  include 'ft8_params.f90'               !Set various constants
  type(hdr) h                            !Header for .wav file
  character arg*12,fname*17,sorm*1
  character msg*22,msgsent*22
  character*6 mygrid6
  logical bcontest
  complex c0(0:NMAX-1)
  complex c(0:NMAX-1)
  integer itone(NN)
  integer*1 msgbits(KK)
  integer*2 iwave(NMAX)                  !Generated full-length waveform
  data mygrid6/'EM48  '/

! Get command-line argument(s)
  nargs=iargc()
  if(nargs.ne.8) then
     print*,'Usage:   ft8sim "message"           s|m  f0    DT fdop del nfiles snr'
     print*,'Example: ft8sim "K1ABC W9XYZ EN37"   m  1500.0 0.0 0.1 1.0   10   -18'
     print*,'s|m: "s" for single signal at 1500 Hz, "m" for 25 signals'
     print*,'f0 is ignored when sorm = m'
     print*,'Make nfiles negative to invoke 72-bit contest mode.'
     go to 999
  endif
  call getarg(1,msg)                     !Message to be transmitted
  call getarg(2,sorm)                    !s for single signal, m for multiple sigs 
  if(sorm.eq."s") then
    print*,"Generating single signal at 1500 Hz."
    nsig=1
  elseif( sorm.eq."m") then
    print*,"Generating 25 signals per file."
    nsig=25
  else
    print*,"sorm parameter must be s (single) or m (multiple)."
    goto 999
  endif
  call getarg(3,arg)
  read(arg,*) f0                         !Frequency (only used for single-signal)
  call getarg(4,arg)
  read(arg,*) xdt                        !Time offset from nominal (s)
  call getarg(5,arg)
  read(arg,*) fspread                    !Watterson frequency spread (Hz)
  call getarg(6,arg)
  read(arg,*) delay                      !Watterson delay (ms)
  call getarg(7,arg)
  read(arg,*) nfiles                     !Number of files
  call getarg(8,arg)
  read(arg,*) snrdb                      !SNR_2500

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
  i3bit=0                                ! ### TEMPORARY ??? ###

! Source-encode, then get itone()
  call genft8(msg,mygrid6,bcontest,i3bit,msgsent,msgbits,itone)
  write(*,1000) f0,xdt,txt,snrdb,bw,msgsent
1000 format('f0:',f9.3,'   DT:',f6.2,'   TxT:',f6.1,'   SNR:',f6.1,    &
          '  BW:',f4.1,2x,a22)

write(*,'(28i1,1x,28i1)') msgbits(1:56)
write(*,'(16i1)') msgbits(57:72)
write(*,'(3i1)') msgbits(73:75)
write(*,'(12i1)') msgbits(76:87)
 
!  call sgran()
  do ifile=1,nfiles
     c=0.
     do isig=1,nsig
        c0=0.
        if(nsig.eq.25) then
          f0=(isig+2)*100.0
        endif
        k=-1 + nint((xdt+0.5+0.01*gran())/dt)
!        k=-1 + nint((xdt+0.5)/dt)
        phi=0.0
        do j=1,NN                             !Generate complex waveform
           dphi=twopi*(f0+itone(j)*baud)*dt
           do i=1,NSPS
              k=k+1
              phi=mod(phi+dphi,twopi)
              if(k.ge.0 .and. k.lt.NMAX) c0(k)=cmplx(cos(phi),sin(phi))
           enddo
        enddo
        if(fspread.ne.0.0 .or. delay.ne.0.0) call watterson(c0,NMAX,fs,delay,fspread)
        c=c+sig*c0
     enddo
     if(snrdb.lt.90) then
        do i=0,NMAX-1                   !Add gaussian noise at specified SNR
           xnoise=gran()
           ynoise=gran()
           c(i)=c(i) + cmplx(xnoise,ynoise)
        enddo
     endif

     fac=32767.0
     rms=100.0
     if(snrdb.ge.90.0) iwave(1:NMAX)=nint(fac*real(c))
     if(snrdb.lt.90.0) iwave(1:NMAX)=nint(rms*real(c))

     h=default_header(12000,NMAX)
     write(fname,1102) ifile
1102 format('000000_',i6.6,'.wav')
     open(10,file=fname,status='unknown',access='stream')
     write(10) h,iwave                !Save to *.wav file
     close(10)
     write(*,1110) ifile,xdt,f0,snrdb,fname
1110 format(i4,f7.2,f8.2,f7.1,2x,a17)
  enddo
       
999 end program ft8sim
