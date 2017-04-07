program dbpsksim

  parameter (ND=121)                    !Data symbols: LDPC (120,60), r=1/2
  parameter (NN=ND)                     !Total symbols (121)
  parameter (NSPS=28800)                !Samples per symbol at 12000 sps
  parameter (NZ=NSPS*NN)                !Samples in waveform (3484800)
  parameter (NFFT1=65536,NH1=NFFT1/2)

  character*8 arg
  complex c(0:NZ-1)                     !Complex waveform
  complex c2(0:NFFT1-1)                 !Short spectra
  complex cr(0:NZ-1)
  complex ct(0:NZ-1)
  complex z0,z,zp
  real s(-NH1+1:NH1)
  real xnoise(0:NZ-1)                   !Generated random noise
  real ynoise(0:NZ-1)                   !Generated random noise
  real rxdata(120),llr(120)
  integer id(NN)                        !Encoded NRZ data (values +/-1)
  integer id1(NN)                       !Recovered data (1st pass)
  integer id2(NN)                       !Recovered data (2nd pass)
!  integer icw(NN)
  integer*1 msgbits(60),decoded(60),codeword(120),apmask(120),cw(120)
  data msgbits/0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,&
       0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,1,0,0,1,0,1,1,0,1,0/

  nnn=0
  nargs=iargc()
  if(nargs.ne.5) then
     print*,'Usage:   dbpsksim f0(Hz) delay(ms) fspread(Hz) iters snr(dB)'
     print*,'Example: dbpsksim 1500 0 0 10 -35'
     print*,'Set snr=0 to cycle through a range'
     go to 999
  endif
  call getarg(1,arg)
  read(arg,*) f0                        !Low tone frequency
  call getarg(2,arg)
  read(arg,*) delay
  call getarg(3,arg)
  read(arg,*) fspread
  call getarg(4,arg)
  read(arg,*) iters
  call getarg(5,arg)
  read(arg,*) snrdb
  
  twopi=8.d0*atan(1.d0)
  fs=12000.d0
  dt=1.0/fs
  ts=NSPS*dt
  baud=1.d0/ts
  txt=NZ*dt
  bandwidth_ratio=2500.0/6000.0
  ndiff=1                                         !Encode/decode differentially
  write(*,1000) baud,5*baud,txt,delay,fspread
1000 format('Baud:',f6.3,'  BW:',f4.1,'  TxT:',f6.1,'  Delay:',f5.2,   &
          '  fSpread:',f5.2/)

  write(*,1004)
1004 format('  SNR    e1   e2   ber1    ber2    fer1   fer2  fsigma'/55('-'))

  call encode120(msgbits,codeword)                !Encode the test message
  isna=-28
  isnb=-40
  if(snrdb.ne.0.0) then
     isna=nint(snrdb)
     isnb=isna
  endif
  do isnr=isna,isnb,-1
     snrdb=isnr
     sig=sqrt(bandwidth_ratio) * 10.0**(0.05*snrdb)
     if(snrdb.gt.90.0) sig=1.0
     nhard1=0
     nhard2=0
     nfe1=0
     nfe2=0
     sqf=0.
     do iter=1,iters
        nnn=nnn+1
        id(1)=1                                  !First bit is always 1
        id(2:NN)=2*codeword-1
        call genbpsk(id,f0,ndiff,0,c)            !Generate the 4-FSK waveform
        if(delay.ne.0.0 .or. fspread.ne.0.0) call watterson(c,delay,fspread)
        c=sig*c                                  !Scale to requested SNR
        if(snrdb.lt.90) then
           do i=0,NZ-1                           !Generate gaussian noise
              xnoise(i)=gran()
              ynoise(i)=gran()
           enddo
           c=c + cmplx(xnoise,ynoise)            !Add noise to signal
        endif

! First attempt at finding carrier frequency fc
        nspec=NZ/NFFT1
        df1=12000.0/NFFT1
        s=0.
        do k=1,nspec
           ia=(k-1)*NSPS
           ib=ia+NSPS-1
           c2(0:NSPS-1)=c(ia:ib)
           c2(NSPS:)=0.
           call four2a(c2,NFFT1,1,-1,1)
           do i=0,NFFT1-1
              j=i
              if(j.gt.NH1) j=j-NFFT1
              s(j)=s(j) + real(c2(i))**2 + aimag(c2(i))**2
           enddo
        enddo        
        s=1.e-6*s
        smax=0.
        ipk=0
        ia=(1400.0)/df1
        ib=(1600.0)/df1
        do i=ia,ib
           f=i*df1
           if(s(i).gt.smax) then
              smax=s(i)
              ipk=i
              fc=f
           endif
        enddo
        a=(s(ipk+1)-s(ipk-1))/2.0
        b=(s(ipk+1)+s(ipk-1)-2.0*s(ipk))/2.0
        dx=-a/(2.0*b)
        fc=fc + df1*dx
        sqf=sqf + (fc-f0)**2

! The following is for testing SNR calibration:
!        sp5n=(s(ipk-2)+s(ipk-1)+s(ipk)+s(ipk+1)+s(ipk+2))  !Sig + 5*noise
!        base=(sum(s)-sp5n)/(NFFT1-5.0)                     !Noise per bin
!        psig=sp5n-5*base                                   !Sig only
!        pnoise=(2500.0/df1)*base                           !Noise in 2500 Hz
!        xsnrdb=db(psig/pnoise)

        call genbpsk(id,fc,ndiff,1,cr)           !Generate reference carrier
        c=c*conjg(cr)                            !Mix to baseband

        z0=1.0
        ie0=1
        do j=1,NN                                !Demodulate
           ia=(j-1)*NSPS
           ib=ia+NSPS-1
           z=sum(c(ia:ib))
           zp=z*conjg(z0)
           p=1.e-4*real(zp)
           id1(j)=-1
           if(p.ge.0.0) id1(j)=1
           if(j.ge.2) rxdata(j-1)=p
           z0=z
           
! For testing, treat every 3rd symbol as having a known value (i.e., as Sync):
!           ie=id(j)*ie0
!           if(mod(j,3).eq.0) write(12,1010) j,ie,1.e-3*ie*z,   &
!                atan2(aimag(ie*z),real(ie*z))
!1010       format(2i4,3f10.3)
!           ie0=ie
        enddo
        nhard1=nhard1 + count(id1.ne.id)           !Count hard errors

        rxav=sum(rxdata)/120
        rx2av=sum(rxdata*rxdata)/120
        rxsig=sqrt(rx2av-rxav*rxav)
        rxdata=rxdata/rxsig
        ss=0.84
        llr=2.0*rxdata/(ss*ss)
        apmask=0
        max_iterations=10
        call bpdecode120(llr,apmask,max_iterations,decoded,niterations,cw)

! Count the hard errors in id1() and icw()
!        icw(1)=1
!        icw(2:NN)=2*cw-1
!        nid1=0
!        ncw=0
!        ie0=1
!        do j=2,NN
!           ib=(id(j)+1)/2
!           ib1=(id1(j)+1)/2
!           if(ib1.ne.ib) nid1=nid1+1
!           if(cw(j-1).ne.ib) ncw=ncw+1
!        enddo
!        print*,niterations,nid1,ncw

! Count frame errors
        if(niterations.lt.0 .or. count(msgbits.ne.decoded).gt.0) nfe1=nfe1+1
       
! Generate a new reference carrier, using first-pass hard bits
        call genbpsk(id1,0.0,ndiff,0,cr)
        ct=c*conjg(cr)
        call four2a(ct,NZ,1,-1,1)
        df2=12000.0/NZ
        pmax=0.
        do i=0,NZ-1
           f=i*df2
           if(i.gt.NZ/2) f=(i-NZ)*df2
           if(abs(f).lt.1.0) then
              p=real(ct(i))**2 + aimag(ct(i))**2
              if(p.gt.pmax) then
                 pmax=p
                 fc2=f
                 ipk=i
              endif
           endif
        enddo

        call genbpsk(id,fc2,ndiff,1,cr)         !Generate new ref carrier at fc2
        c=c*conjg(cr)
        z0=1.0
        do j=1,NN                                !Demodulate
           ia=(j-1)*NSPS
           ib=ia+NSPS-1
           z=sum(c(ia:ib))
           zp=z*conjg(z0)
           p=1.e-4*real(zp)
           id2(j)=-1
           if(p.ge.0.0) id2(j)=1
           if(j.ge.2) rxdata(j-1)=p
           z0=z
        enddo
        nhard2=nhard2 + count(id2.ne.id)           !Count hard errors

        rxav=sum(rxdata)/120
        rx2av=sum(rxdata*rxdata)/120
        rxsig=sqrt(rx2av-rxav*rxav)
        rxdata=rxdata/rxsig
        ss=0.84
        llr=2.0*rxdata/(ss*ss)               !Soft symbols
        apmask=0
        max_iterations=10
        call bpdecode120(llr,apmask,max_iterations,decoded,niterations,cw)
        if(niterations.ge.0) call chkcrc10(decoded,nbadcrc)
        if(niterations.lt.0 .or. count(msgbits.ne.decoded).gt.0 .or.        &
             nbadcrc.ne.0) nfe2=nfe2+1
     enddo
     
     fsigma=sqrt(sqf/iters)
     ber1=float(nhard1)/(NN*iters)
     ber2=float(nhard2)/(NN*iters)
     fer1=float(nfe1)/iters
     fer2=float(nfe2)/iters
     write(*,1050)  snrdb,nhard1,nhard2,ber1,ber2,fer1,fer2,fsigma
     write(14,1050) snrdb,nhard1,nhard2,ber1,ber2,fer1,fer2,fsigma
1050 format(f6.1,2i5,2f8.4,2f7.3,f8.2,3i5)
  enddo

999 end program dbpsksim
