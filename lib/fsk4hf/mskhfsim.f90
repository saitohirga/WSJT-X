program msksim

! Simulate characteristics of a potential "MSK10" mode using LDPC (168,84)
! code, OQPDK modulation, and 30 s T/R sequences.

! Reception and Demodulation algorithm:
!   1. Compute coarse spectrum; find fc1 = approx carrier freq
!   2. Mix from fc1 to 0; LPF at +/- 0.75*R
!   3. Square, FFT; find peaks near -R/2 and +R/2 to get fc2
!   4. Mix from fc2 to 0
!   5. Fit cb13 (central part of csync) to c -> lag, phase
!   6. Fit complex ploynomial for channel equalization
!   7. Get soft bits from equalized data

  parameter (KK=84)                     !Information bits (72 + CRC12)
  parameter (ND=168)                    !Data symbols: LDPC (168,84), r=1/2
  parameter (NS=65)                     !Sync symbols (2 x 26 + Barker 13)
  parameter (NR=3)                      !Ramp up/down
  parameter (NN=NR+NS+ND)               !Total symbols (236)
  parameter (NSPS=16)                   !Samples per MSK symbol (16)
  parameter (N2=2*NSPS)                 !Samples per OQPSK symbol (32)
  parameter (N13=13*N2)                 !Samples in central sync vector (416)
  parameter (NZ=NSPS*NN)                !Samples in baseband waveform (3760)
  parameter (NFFT1=4*NSPS,NH1=NFFT1/2)

  character*8 arg
  complex cbb(0:NZ-1)                   !Complex baseband waveform
  complex csync(0:NZ-1)                 !Sync symbols only, from cbb
  complex cb13(0:N13-1)                 !Barker 13 waveform
  complex c(0:NZ-1)                     !Complex waveform
  complex zz(NS+ND)                     !Complex symbol values (intermediate)
  complex z
  real xnoise(0:NZ-1)                   !Generated random noise
  real ynoise(0:NZ-1)                   !Generated random noise
  real rxdata(ND),llr(ND)               !Soft symbols
  real pp(2*NSPS)                       !Shaped pulse for OQPSK
  real a(5)                             !For twkfreq1
  real aa(20),bb(20)                    !Fitted polyco's
  integer id(NS+ND)                     !NRZ values (+/-1) for Sync and Data
  integer ierror(NS+ND)
  integer icw(NN)
  integer*1 msgbits(KK),decoded(KK),apmask(ND),cw(ND)
!  integer*1 codeword(ND)
  data msgbits/0,0,1,0,0,1,1,1,1,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,1,1,0,0,0,1, &
       1,1,1,0,1,1,1,1,1,1,1,0,0,1,0,0,1,1,0,1,0,1,1,1,0,1,1,0,1,1,         &
       1,1,0,1,0,1,1,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0/

  nargs=iargc()
  if(nargs.ne.6) then
     print*,'Usage:   msksim f0(Hz) delay(ms) fspread(Hz) maxn iters snr(dB)'
     print*,'Example: msksim 20 0 0 5 10 -20'
     print*,'Set snr=0 to cycle through a range'
     go to 999
  endif
  call getarg(1,arg)
  read(arg,*) f0                           !Generated carrier frequency
  call getarg(2,arg)
  read(arg,*) delay                      !Delta_t (ms) for Watterson model
  call getarg(3,arg)
  read(arg,*) fspread                    !Fspread (Hz) for Watterson model
  call getarg(4,arg)
  read(arg,*) maxn                       !Max nterms for polyfit
  call getarg(5,arg)
  read(arg,*) iters                      !Iterations at each SNR
  call getarg(6,arg)
  read(arg,*) snrdb                      !Specified SNR_2500
  
  twopi=8.0*atan(1.0)
  fs=12000.0/72.0                        !Sample rate = 166.6666667 Hz
  dt=1.0/fs                              !Sample interval (s)
  tt=NSPS*dt                             !Duration of "itone" symbols (s)
  ts=2*NSPS*dt                           !Duration of OQPSK symbols (s)
  baud=1.0/tt                            !Keying rate for "itone" symbols (baud)
  txt=NZ*dt                              !Transmission length (s)
  bandwidth_ratio=2500.0/(fs/2.0)
  write(*,1000) f0,delay,fspread,maxn,iters,baud,1.5*baud,txt
1000 format('f0:',f5.1,'  Delay:',f4.1,'  fSpread:',f5.2,'  maxn:',i3,   &
          '  Iters:',i6/'Baud:',f7.3,'  BW:',f5.1,'  TxT:',f5.1,f5.2/)
  write(*,1004)
1004 format(/'  SNR     err    ber    fer   fsigma'/37('-'))

  do i=1,N2                              !Half-sine pulse shape
     pp(i)=sin(0.5*(i-1)*twopi/(2*NSPS))
  enddo
  
  call genmskhf(msgbits,id,icw,cbb,csync) !Generate baseband waveform and csync
  cb13=csync(1680:2095)                  !Copy the Barker 13 waveform

  a=0.
  a(1)=f0
  call twkfreq1(cbb,NZ,fs,a,cbb)         !Mix to specified frequency

  isna=-10
  isnb=-30
  if(snrdb.ne.0.0) then
     isna=nint(snrdb)
     isnb=isna
  endif
  do isnr=isna,isnb,-1                   !Loop over SNR range
     snrdb=isnr
     sig=sqrt(bandwidth_ratio) * 10.0**(0.05*snrdb)
     if(snrdb.gt.90.0) sig=1.0
     nhard=0
     nhardsync=0
     nfe=0
     sqf=0.
     do iter=1,iters                     !Loop over requested iterations
        nhard0=0
        nhardsync0=0
        c=cbb
        if(delay.ne.0.0 .or. fspread.ne.0.0) call watterson(c,fs,delay,fspread)
        c=sig*c                                  !Scale to requested SNR
        if(snrdb.lt.90) then
           do i=0,NZ-1                           !Generate gaussian noise
              xnoise(i)=gran()
              ynoise(i)=gran()
           enddo
           c=c + cmplx(xnoise,ynoise)            !Add AWGN noise
        endif

        call getfc1(c,fc1)                       !First approx for freq
        call getfc2(c,fc1,fc2)                   !Refined freq
        sqf=sqf + (fc1+fc2-f0)**2
        a(1)=-(fc1+fc2)
        a(2:5)=0.
        call twkfreq1(c,NZ,fs,a,c)          !Mix c down by fc1+fc2

! The following may not be necessary?
!        z=sum(c(1680:2095)*cb13)/208.0     !Get phase from Barker 13 vector
!        z0=z/abs(z)
!        c=c*conjg(z0)

!---------------------------------------------------------------- DT
! Not presently used:
        amax=0.
        jpk=0
        do j=-20*NSPS,20*NSPS              !Get jpk
           z=sum(c(1680+j:2095+j)*cb13)/208.0
           if(abs(z).gt.amax) then
              amax=abs(z)
              jpk=j
           endif
        enddo
        xdt=jpk/fs
   
        call cpolyfit(c,pp,id,maxn,aa,bb,zz)
        nterms=maxn

        call msksoftsym(zz,aa,bb,id,nterms,ierror,rxdata,nhard0,nhard,   &
             nhardsync0,nhardsync)
        
!---------------------------------------------------------------- Decode
        rxav=sum(rxdata)/ND
        rx2av=sum(rxdata*rxdata)/ND
        rxsig=sqrt(rx2av-rxav*rxav)
        rxdata=rxdata/rxsig
        ss=0.84
        llr=2.0*rxdata/(ss*ss)
        apmask=0
        max_iterations=40
        call bpdecode168(llr,apmask,max_iterations,decoded,niterations,cw)
        nbadcrc=0
        ifer=0
        if(niterations.ge.0) call chkcrc12(decoded,nbadcrc)
        if(niterations.lt.0 .or. count(msgbits.ne.decoded).gt.0 .or.        &
             nbadcrc.ne.0) ifer=1
        nfe=nfe+ifer
     enddo

     fsigma=sqrt(sqf/iters)
     ber=float(nhard)/((NS+ND)*iters)
     fer=float(nfe)/iters
     write(*,1050)  snrdb,nhard,ber,fer,fsigma
     write(60,1050)  snrdb,nhard,ber,fer,fsigma
1050 format(f6.1,i7,f8.4,f7.3,f8.2)
  enddo

999 end program msksim
