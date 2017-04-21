program fsk4hf

! Simulate characteristics of a potential mode using LDPC (168,84) code,
! 4-FSK modulation, and 30 s T/R sequences.

  parameter (KK=84)                     !Information bits (72 + CRC12)
  parameter (ND=84)                     !Data symbols: LDPC (168,84), r=1/2
  parameter (NS=12)                     !Sync symbols (3 @ 4x4 Costas arrays)
  parameter (NR=2)                      !Ramp up/down
  parameter (NN=NR+NS+ND)               !Total symbols (98)
  parameter (NSPS=2688/84)              !Samples per symbol (32)
  parameter (NZ=NSPS*NN)                !Samples in baseband waveform (3760)

  character*8 arg
  complex c0(0:NZ-1)                    !Complex waveform
  complex c(0:NZ-1)                     !Complex waveform
  real xnoise(0:NZ-1)                   !Generated random noise
  real ynoise(0:NZ-1)                   !Generated random noise
  real rxdata(2*ND),llr(2*ND)           !Soft symbols
  real s(0:NSPS,NN)
  real savg(0:NSPS)
  real ps(0:3)
  integer id(ND)                        !Symbol values (0-3), data only
  integer id1(ND)                       !Recovered data values
  integer*1 msgbits(KK),decoded(KK),apmask(ND),cw(ND)
  data msgbits/0,0,1,0,0,1,1,1,1,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,1,1,0,0,0,1, &
       1,1,1,0,1,1,1,1,1,1,1,0,0,1,0,0,1,1,0,1,0,1,1,1,0,1,1,0,1,1,         &
       1,1,0,1,0,1,1,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0/

  nargs=iargc()
  if(nargs.ne.5) then
     print*,'Usage:   fsk4hf f0(Hz) delay(ms) fspread(Hz) iters snr(dB)'
     print*,'Example: fsk4hf 20 0 0 10 -20'
     print*,'Set snr=0 to cycle through a range'
     go to 999
  endif
  call getarg(1,arg)
  read(arg,*) f0                         !Generated carrier frequency
  call getarg(2,arg)
  read(arg,*) delay                      !Delta_t (ms) for Watterson model
  call getarg(3,arg)
  read(arg,*) fspread                    !Fspread (Hz) for Watterson model
  call getarg(4,arg)
  read(arg,*) iters                      !Iterations at each SNR
  call getarg(5,arg)
  read(arg,*) snrdb                      !Specified SNR_2500
  
  twopi=8.0*atan(1.0)
  fs=12000.0/84.0                        !Sample rate = 142.857... Hz
  dt=1.0/fs                              !Sample interval (s)
  tt=NSPS*dt                             !Duration of "itone" symbols (s)
  baud=1.0/tt                            !Keying rate for "itone" symbols (baud)
  txt=NZ*dt                              !Transmission length (s)
  bandwidth_ratio=2500.0/(fs/2.0)
  write(*,1000) f0,delay,fspread,iters,baud,4*baud,txt
1000 format('f0:',f5.1,'  Delay:',f4.1,'  fSpread:',f5.2,                    &
          '  Iters:',i6/'Baud:',f7.3,'  BW:',f5.1,'  TxT:',f5.1,f5.2/)
  write(*,1004)
1004 format(/'  SNR    sym   bit    ser     ber    fer   fsigma'/50('-'))
  
  call genfsk4hf(msgbits,f0,id,c0)       !Generate baseband waveform
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
     nbit=0
     nfe=0
     sqf=0.
     do iter=1,iters                     !Loop over requested iterations
        c=c0
        if(delay.ne.0.0 .or. fspread.ne.0.0) then
           call watterson(c,NZ,fs,delay,fspread)
        endif
        c=sig*c                          !Scale to requested SNR
        if(snrdb.lt.90) then
           do i=0,NZ-1                   !Generate gaussian noise
              xnoise(i)=gran()
              ynoise(i)=gran()
           enddo
           c=c + cmplx(xnoise,ynoise)    !Add AWGN noise
        endif
        df=fs/(2*NSPS)
        i0=nint(f0/df)
        call spec4(c,s,savg)
        do i=0,NSPS
           write(12,3001) i*df,savg(i),db(savg(i))
3001       format(3f15.3)
        enddo
        
        do j=1,ND
           nlo=0
           nhi=0
           k=j+5
           if(j.ge.43) k=j+9
           ps=s(i0:i0+6:2,k)
           ps=sqrt(ps)  !###
           rlo=max(ps(1),ps(3))-max(ps(0),ps(2))
           rhi=max(ps(2),ps(3))-max(ps(0),ps(1))
           if(rlo.ge.0.0) nlo=1
           if(rhi.ge.0.0) nhi=1
           rxdata(2*j-1)=rhi
           rxdata(2*j)=rlo
           id1(j)=2*nhi+nlo
        enddo
!        write(*,1001) id(1:70)
!        write(*,1001) id1(1:70)
!1001    format(70i1)
        nhard=nhard+count(id.ne.id1)
        nbit=nbit + count(iand(id,1).ne.iand(id1,1)) +               &
             count(iand(id,2).ne.iand(id1,2))
        
        rxav=sum(rxdata)/ND
        rx2av=sum(rxdata*rxdata)/ND
        rxsig=sqrt(rx2av-rxav*rxav)
        rxdata=rxdata/rxsig
        ss=0.84
        llr=2.0*rxdata/(ss*ss)
        apmask=0
        max_iterations=40
        ifer=0
        call bpdecode168(llr,apmask,max_iterations,decoded,niterations,cw)
        nbadcrc=0
        if(niterations.ge.0) call chkcrc12(decoded,nbadcrc)
        if(niterations.lt.0 .or. count(msgbits.ne.decoded).gt.0 .or.        &
             nbadcrc.ne.0) ifer=1
        nfe=nfe+ifer
     enddo

     fsigma=sqrt(sqf/iters)
     ser=float(nhard)/(ND*iters)
     ber=float(nbit)/(2*ND*iters)
     fer=float(nfe)/iters
     write(*,1050)  snrdb,nhard,nbit,ser,ber,fer,fsigma
!     write(60,1050)  snrdb,nhard,ber,fer,fsigma
1050 format(f6.1,2i6,2f8.4,f7.3,f8.2)
  enddo

999 end program fsk4hf
