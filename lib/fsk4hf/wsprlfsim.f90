program wsprlfsim

! Simulate characteristics of a potential "WSPR-LF" mode using LDPC (300,60)
! code, OQPSK modulation, and 5 minute T/R sequences.

! Reception and Demodulation algorithm:
!   1. Compute coarse spectrum; find fc1 = approx carrier freq
!   2. Mix from fc1 to 0; LPF at +/- 0.75*R
!   3. Square, FFT; find peaks near -R/2 and +R/2 to get fc2
!   4. Mix from fc2 to 0
!   5. Fit cb13 (central part of csync) to c -> lag, phase
!   6. Fit complex ploynomial for channel equalization
!   7. Get soft bits from equalized data

  include 'wsprlf_params.f90'

! Q: Would it be better for central Sync array to use both I and Q channels?
  
  character*8 arg
  complex cbb(0:NZ-1)                   !Complex baseband waveform
  complex csync(0:NZ-1)                 !Sync symbols only, from cbb
  complex c(0:NZ-1)                     !Complex waveform
  complex c0(0:NZ-1)                    !Complex waveform
  complex c1(0:NZ-1)                    !Complex waveform
  complex zz(NS+ND)                     !Complex symbol values (intermediate)
  complex z
  real xnoise(0:NZ-1)                   !Generated random noise
  real ynoise(0:NZ-1)                   !Generated random noise
  real rxdata(ND),llr(ND)               !Soft symbols
  real pp(2*NSPS)                       !Shaped pulse for OQPSK
  real a(5)                             !For twkfreq1
  real aa(20),bb(20)                    !Fitted polyco's
  real t(11)
  character*12 label(11)
  integer*8 count0,count1,count2,count3,clkfreq
  integer nc(11)
  integer id(NS+ND)                     !NRZ values (+/-1) for Sync and Data
  integer ierror(NS+ND)
  integer icw(NN)
  integer itone(NN)
  integer*1 msgbits(KK),decoded(KK),apmask(ND),cw(ND)
!  integer*1 codeword(ND)
  data msgbits/0,0,1,0,0,1,1,1,1,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,1,1,0,0,0,1, &
       1,1,1,0,1,1,1,1,1,1,1,0,0,1,0,0,1,1,0,1,1,0,1,0,1,1,0,0,1,1/
  data label/'genwsprlf','twkfreq1 a','watterson','noise gen','getfc1w',    &
       'getfc2w','twkfreq1 b','xdt loop','cpolyfitw','msksoftsym',          &
       'bpdecode300'/
  
  nargs=iargc()
  if(nargs.ne.6) then
     print*,'Usage:   wsprlfsim f0(Hz) delay(ms) fspread(Hz) maxn iters snr(dB)'
     print*,'Example: wsprlfsim 0 0 0 5 10 -20'
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
  read(arg,*) maxn                       !Max nterms for polyfit
  call getarg(5,arg)
  read(arg,*) iters                      !Iterations at each SNR
  call getarg(6,arg)
  read(arg,*) snrdb                      !Specified SNR_2500

  nc=0
  twopi=8.0*atan(1.0)
  fs=NSPS*12000.0/NSPS0                  !Sample rate = 22.2222... Hz
  dt=1.0/fs                              !Sample interval (s)
  tt=NSPS*dt                             !Duration of "itone" symbols (s)
  ts=2*NSPS*dt                           !Duration of OQPSK symbols (s)
  baud=1.0/tt                            !Keying rate for "itone" symbols (baud)
  txt=NZ*dt                              !Transmission length (s)
  bandwidth_ratio=2500.0/(fs/2.0)
  write(*,1000) fs,f0,delay,fspread,maxn,baud,3*baud,txt,iters
1000 format('fs:',f10.3,'  f0:',f5.1,'  Delay:',f4.1,'  fSpread:',f5.2,   &
          '  maxn:',i3,/'Baud:',f8.3,'  BW:',f5.1,'  TxT:',f6.1,'  iters:',i4/)
  write(*,1004)
1004 format(/'  SNR     sync   data   ser     ber    fer   fsigma  tsigma',   &
          '    tsec'/68('-'))

  do i=1,N2                              !Half-sine pulse shape
     pp(i)=sin(0.5*(i-1)*twopi/(2*NSPS))
  enddo

  t=0.
  call system_clock(count0,clkfreq)
  call genwsprlf(msgbits,id,icw,cbb,csync,itone)!Generate baseband waveform
  call system_clock(count1,clkfreq)
  t(1)=float(count1-count0)/float(clkfreq)
  nc(1)=nc(1)+1
  do i=0,NZ-1
     write(40,4001) i,cbb(i),csync(i)
4001 format(i8,4f12.6)
  enddo

  call system_clock(count0,clkfreq)
  a=0.
  a(1)=f0
  call twkfreq1(cbb,NZ,fs,a,c0)          !Mix baseband to specified frequency
  call system_clock(count1,clkfreq)
  t(2)=float(count1-count0)/float(clkfreq)
  nc(2)=nc(2)+1

  isna=-20
  isnb=-40
  if(snrdb.ne.0.0) then
     isna=nint(snrdb)
     isnb=isna
  endif
  do isnr=isna,isnb,-1                   !Loop over SNR range
     if(isna.ne.isnb) snrdb=isnr
     sig=sqrt(bandwidth_ratio) * 10.0**(0.05*snrdb)
     if(snrdb.gt.90.0) sig=1.0
     nhard=0
     nhardsync=0
     nfe=0
     sqf=0.
     sqt=0.
     
     call system_clock(count2,clkfreq)
     do iter=1,iters                     !Loop over requested iterations
        c=c0
write(*,*) 'iter ',iter  
        call system_clock(count0,clkfreq)
        if(delay.ne.0.0 .or. fspread.ne.0.0) then
           call watterson(c,NZ,fs,delay,fspread)
        endif
        call system_clock(count1,clkfreq)
        t(3)=t(3)+float(count1-count0)/float(clkfreq)
        nc(3)=nc(3)+1

        call system_clock(count0,clkfreq)
        c=sig*c                          !Scale to requested SNR
        if(snrdb.lt.90) then
           do i=0,NZ-1                   !Generate gaussian noise
              xnoise(i)=gran()
              ynoise(i)=gran()
           enddo
           c=c + cmplx(xnoise,ynoise)    !Add AWGN noise
        endif
        call system_clock(count1,clkfreq)
        t(4)=t(4)+float(count1-count0)/float(clkfreq)
        nc(4)=nc(4)+1

        call system_clock(count0,clkfreq)
        call getfc1w(c,fs,fc1)               !First approx for freq
        call system_clock(count1,clkfreq)
        t(5)=t(5)+float(count1-count0)/float(clkfreq)
        nc(5)=nc(5)+1
write(*,*) 'fc1 ',fc1
        call system_clock(count0,clkfreq)
        call getfc2w(c,csync,fs,fc1,fc2,fc3) !Refined freq
write(*,*) 'fc1,fc2,fc3 ',fc1,fc2,fc3
        call system_clock(count1,clkfreq)
        t(6)=t(6)+float(count1-count0)/float(clkfreq)
        nc(6)=nc(6)+1
        sqf=sqf + (fc1+fc2-f0)**2
        
        call system_clock(count0,clkfreq)
!NB: Measured performance is about equally good using fc2 or fc3 here:
        a(1)=-(fc1+fc2)
        a(2:5)=0.
        call twkfreq1(c,NZ,fs,a,c)       !Mix c down by fc1+fc2
        call system_clock(count1,clkfreq)
        t(7)=t(7)+float(count1-count0)/float(clkfreq)
        nc(7)=nc(7)+1

! The following may not be necessary?
!        z=sum(c(3088:3503)*cb13)/208.0     !Get phase from Barker 13 vector
!        z0=z/abs(z)
!        c=c*conjg(z0)

        call system_clock(count0,clkfreq)
!---------------------------------------------------------------- DT
! Not presently used:
        amax=0.
        jpk=0
        iaa=0
        ibb=NZ-1
        do j=-20*NSPS,20*NSPS,NSPS/8
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
           if(abs(z).gt.amax) then
              amax=abs(z)
              jpk=j
           endif
        enddo
        xdt=jpk/fs
        sqt=sqt + xdt**2
        call system_clock(count1,clkfreq)
        t(8)=t(8)+float(count1-count0)/float(clkfreq)
        nc(8)=nc(8)+1

!-----------------------------------------------------------------        

        nterms=maxn
        c1=c
        do itry=1,20
           idf=itry/2
           if(mod(itry,2).eq.0) idf=-idf
           nhard0=0
           nhardsync0=0
           ifer=1
           a(1)=idf*0.00085
           a(2:5)=0.
           call system_clock(count0,clkfreq)
           call twkfreq1(c1,NZ,fs,a,c)       !Mix c1 into c
           call cpolyfitw(c,pp,id,maxn,aa,bb,zz,nhs)
           call system_clock(count1,clkfreq)
           t(9)=t(9)+float(count1-count0)/float(clkfreq)
           nc(9)=nc(9)+1

           call system_clock(count0,clkfreq)
           call msksoftsymw(zz,aa,bb,id,nterms,ierror,rxdata,nhard0,nhardsync0)
           call system_clock(count1,clkfreq)
           t(10)=t(10)+float(count1-count0)/float(clkfreq)
           nc(10)=nc(10)+1

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
           call system_clock(count0,clkfreq)
           call bpdecode300(llr,apmask,max_iterations,decoded,niterations,cw)
           call system_clock(count1,clkfreq)
           t(11)=t(11)+float(count1-count0)/float(clkfreq)
           nc(11)=nc(11)+1
           nbadcrc=0
           if(niterations.ge.0) call chkcrc10(decoded,nbadcrc)
           if(niterations.lt.0 .or. count(msgbits.ne.decoded).gt.0 .or.     &
                nbadcrc.ne.0) ifer=1
           if(ifer.eq.0) exit
        enddo                                !Freq dither loop
        nhard=nhard+nhard0
        nhardsync=nhardsync+nhardsync0
        nfe=nfe+ifer
        if(nhardsync0+nhard0+niterations+ifer.gt.0) write(42,1045) snrdb,  &
             nhardsync0,nhard0,niterations,ifer,xdt
1045    format(f6.1,4i6,f8.2)
     enddo
     call system_clock(count3,clkfreq)
     tsec=float(count3-count2)/float(clkfreq)

     fsigma=sqrt(sqf/iters)
     tsigma=sqrt(sqt/iters)
     ser=float(nhardsync)/(NS*iters)
     ber=float(nhard)/(ND*iters)
     fer=float(nfe)/iters
     write(*,1050)  snrdb,nhardsync,nhard,ser,ber,fer,fsigma,tsigma,tsec
1050 format(f6.1,2i7,2f8.4,f7.3,2f8.2f8.3)
  enddo
  
  write(*,1060) NS*iters,ND*iters
1060 format(68('-')/6x,2i7)
  
  write(*,1065)
1065 format(/'Timing           sec      frac    calls'/39('-'))
  do i=1,11
     write(*,1070) label(i),t(i),t(i)/sum(t),nc(i)
1070 format(a12,2f9.3,i8)
  enddo
  write(*,1072) sum(t),1.0
1072 format(39('-')/12x,2f10.3)
  
999 end program wsprlfsim
