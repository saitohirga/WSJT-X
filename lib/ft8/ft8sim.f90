program ft8sim

! Generate simulated data for a 15-second HF/6m mode using 8-FSK.
! Output is saved to a *.wav file.

  use wavhdr
  include 'ft8_params.f90'               !Set various constants
  parameter (NWAVE=NN*NSPS)
  type(hdr) h                            !Header for .wav file
  character arg*12,fname*17
  character msg40*40,msg*22,msgsent*22,msg0*22
  character*6 mygrid6
  logical bcontest
  complex c0(0:NMAX-1)
  complex c(0:NMAX-1)
  real wave(NMAX)
  integer itone(NN)
  integer*1 msgbits(91)
  integer*2 iwave(NMAX)                  !Generated full-length waveform
  data mygrid6/'EM48  '/

! Get command-line argument(s)
  nargs=iargc()
  if(nargs.ne.9) then
     print*,'Usage:    ft8sim "message"         nsig|f0  DT fdop del width nfiles snr type'
     print*,'Examples: ft8sim "K1ABC W9XYZ EN37" 1500.0 0.0  0.1 1.0   0     10   -18  1'
     print*,'          ft8sim "K1ABC W9XYZ EN37"   10   0.0  0.1 1.0  25     10   -18  1'
     print*,'          ft8sim "K1ABC W9XYZ EN37"   25   0.0  0.1 1.0  25     10   -18  1'
     print*,'          ft8sim "K1ABC RR73; W9XYZ <KH1/KH7Z> -11" 300 0 0 0 25 1 -10  1'
     print*,'Make nfiles negative to invoke 72-bit contest mode.'
     go to 999
  endif
  call getarg(1,msg40)                   !Message to be transmitted
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
  call getarg(9,arg)
  read(arg,*) itype                      !itype=1 for (174,87), itype=2 for (174,91)

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
  if(index(msg40,';').le.0) then
     i3bit=0
     msg=msg40(1:22)
     if(itype.eq.1) then
        call genft8(msg,mygrid6,bcontest,i3bit,msgsent,msgbits,itone)
     elseif(itype.eq.2) then
        call genft8_174_91(msg,mygrid6,bcontest,i3bit,msgsent,msgbits,itone)
     endif
     write(*,1000) f0,xdt,txt,snrdb,bw,msgsent
1000 format('f0:',f9.3,'   DT:',f6.2,'   TxT:',f6.1,'   SNR:',f6.1,    &
          '  BW:',f4.1,2x,a22)
  else
     call foxgen_wrap(msg40,msgbits,itone)
     write(*,1001) f0,xdt,txt,snrdb,bw,msg40
1001 format('f0:',f9.3,'   DT:',f6.2,'   TxT:',f6.1,'   SNR:',f6.1,    &
          '  BW:',f4.1,2x,a40)
  endif

  write(*,1030) msgbits(1:56)
1030 format(/'Call1: ',28i1,'    Call2: ',28i1)
  if(itype.eq.1) then
     write(*,1032) msgbits(57:72),msgbits(73:75),msgbits(76:87)
1032 format('Grid:  ',16i1,'   3Bit: ',3i1,'    CRC12: ',12i1)
  elseif(itype.eq.2) then
     write(*,1033) msgbits(57:72),msgbits(73:77),msgbits(78:91)
1033 format('Grid:  ',16i1,'  5Bit: ',5i1,'   CRC14: ',14i1)
  endif
  write(*,1034) itone
1034 format(/'Channel symbols:'/79i1/)

  msg0=msg
  do ifile=1,nfiles
     c=0.
     do isig=1,nsig
        c0=0.
        if(nsig.eq.2) then
           if(index(msg,'R-').gt.0) f0=500
           i1=index(msg,' ')
           msg(i1+4:i1+4)=char(ichar('A')+isig-1)
           if(isig.eq.2) then
              f0=f0+100
           endif
           if(itype.eq.1) then
              call genft8(msg,mygrid6,bcontest,i3bit,msgsent,msgbits,itone)
           elseif(itype.eq.2) then
              call genft8_174_91(msg,mygrid6,bcontest,i3bit,msgsent,msgbits,itone)
           endif
        endif
        if(nsig.eq.25) then
           f0=(isig+2)*100.0
        else if(nsig.eq.50) then
           msg=msg0
           f0=1000.0 + (isig-1)*60.0
           i1=index(msg,' ')
           i2=index(msg(i1+1:),' ') + i1
           msg(i1+2:i1+2)=char(ichar('0')+mod(isig-1,10))
           msg(i1+3:i1+3)=char(ichar('A')+mod(isig-1,26))
           msg(i1+4:i1+4)=char(ichar('A')+mod(isig-1,26))
           msg(i1+5:i1+5)=char(ichar('A')+mod(isig-1,26))
           write(msg(i2+3:i2+4),'(i2.2)') isig-1
           if(ifile.ge.2 .and. isig.eq.ifile-1) then
              write(msg(i2+1:i2+4),1002) -isig
1002          format('R',i3.2)
              f0=600.0 + mod(isig-1,5)*60.0
           endif
           if(itype.eq.1) then
              call genft8(msg,mygrid6,bcontest,i3bit,msgsent,msgbits,itone)
           elseif(itype.eq.2) then
              call genft8_174_91(msg,mygrid6,bcontest,i3bit,msgsent,msgbits,itone)
           endif
        endif
        k=-1 + nint((xdt+0.5+0.01*gran())/dt)
!        k=-1 + nint((xdt+0.5)/dt)
        ia=k+1
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
     ib=k
     wave=real(c)
     peak=maxval(abs(wave(ia:ib)))
     rms=sqrt(dot_product(wave(ia:ib),wave(ia:ib))/NWAVE)
     nslots=1
     if(width.gt.0.0) call filt8(f0,nslots,width,wave)
     
     if(snrdb.lt.90) then
        do i=1,NMAX                   !Add gaussian noise at specified SNR
           xnoise=gran()
!           wave(i)=wave(i) + xnoise
!           if(i.ge.ia .and. i.le.ib) write(30,3001) i,wave(i)/peak
!3001       format(i8,f12.6)
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
  enddo
       
999 end program ft8sim

  
