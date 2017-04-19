program fsk4sim

  parameter (ND=60)                      !Data symbols: LDPC (120,60), r=1/2
  parameter (NN=ND)                      !Total symbols (60)
  parameter (NSPS=57600)                 !Samples per symbol at 12000 sps
  parameter (NZ=NSPS*NN)                 !Samples in waveform (3456000)

  character*8 arg
  complex c(0:NZ-1)                      !Complex waveform
  complex cr(0:NZ-1)
  complex cs(NSPS,NN)
  complex cps(0:3)
  complex ct(0:2*NN-1)
  complex z,w,zsum
  real r(0:NZ-1)
  real s(NSPS,NN)
  real savg(NSPS)
  real tmp(NN)                          !For generating random data
  real xnoise(0:NZ-1)                   !Generated random noise
  real ps(0:3)
  integer id(NN)                         !Encoded 2-bit data (values 0-3)
  integer id2(NN)                        !Recovered data
  equivalence (r,cr)

  nnn=0
  nargs=iargc()
  if(nargs.ne.6) then
     print*,'Usage: fsk8sim f0 delay(ms) fspread(Hz) nts iters snr(dB)'
     go to 999
  endif
  call getarg(1,arg)
  read(arg,*) f0                        !Low tone frequency
  call getarg(2,arg)
  read(arg,*) delay
  call getarg(3,arg)
  read(arg,*) fspread
  call getarg(4,arg)
  read(arg,*) nts
  call getarg(5,arg)
  read(arg,*) iters
  call getarg(6,arg)
  read(arg,*) snrdb

  twopi=8.d0*atan(1.d0)
  fs=12000.d0
  dt=1.0/fs
  ts=NSPS*dt
  baud=1.d0/ts
  txt=NZ*dt
  bandwidth_ratio=2500.0/6000.0
  write(*,1000) baud,5*baud,txt,delay,fspread,nts
1000 format('Baud:',f6.3,'  BW:',f5.1,'  TxT:',f5.1,'  Delay:',f5.2,   &
          '  fSpread:',f5.2,'  nts:',i3/)

  write(*,1004)
1004 format('  SNR    Sym  Bit   SER     BER    Sym  Bit   SER     BER'/59('-'))

  isna=-25
  isnb=-40
  if(snrdb.ne.0.0) then
     isna=nint(snrdb)
     isnb=isna
  endif
  do isnr=isna,isnb,-1
     snrdb=isnr
     sig=sqrt(2*bandwidth_ratio) * 10.0**(0.05*snrdb)
     if(snrdb.gt.90.0) sig=1.0
     nhard1=0
     nhard2=0
     nbit1=0
     nbit2=0
     nh2=0
     nb2=0
     do iter=1,iters
        nnn=nnn+1
        id=0
        call random_number(tmp)
        where(tmp.ge.0.25 .and. tmp.lt.0.50) id=1
        where(tmp.ge.0.50 .and. tmp.lt.0.75) id=2
        where(tmp.ge.0.75) id=3

        call genfsk4(id,f0,nts,c)                !Generate the 4-FSK waveform
        call watterson(c,delay,fspread)
        if(sig.ne.1.0) c=sig*c                   !Scale to requested SNR
        if(snrdb.lt.90) then
           do i=0,NZ-1                           !Generate gaussian noise
              xnoise(i)=gran()
           enddo
        endif
        r(0:NZ-1)=real(c(0:NZ-1)) + xnoise       !Add noise to signal
        
        call snr2_wsprlf(r,freq,snr2500,width,1)
        write(*,3001) freq,snr2500,width
3001    format(40x,3f10.3)
        
        df=12000.0/(2*NSPS)
!        i0=nint(f0/df)
!        i0=nint((1500.0+freq)/df)
        i0=nint((f0+freq)/df)
        call spec4(r,cs,s,savg)

        do j=1,NN
           nlo=0
           nhi=0
           ps=s(i0:i0+6*nts:2*nts,j)
           cps=cs(i0:i0+6*nts:2*nts,j)
           if(max(ps(1),ps(3)).ge.max(ps(0),ps(2))) nlo=1
           if(max(ps(2),ps(3)).ge.max(ps(0),ps(1))) nhi=1
           id2(j)=2*nhi+nlo
           z=cps(id2(j))
           ct(j-1)=z
        enddo
        nh1=count(id.ne.id2)
        nb1=count(iand(id,1).ne.iand(id2,1)) + count(iand(id,2).ne.iand(id2,2))

        ct(NN:)=0.
        call four2a(ct,2*NN,1,-1,1)
        df2=baud/(2*NN)
        ct=cshift(ct,NN)
        ppmax=0.
        dfpk=0.
        do i=0,2*NN-1
           f=(i-NN)*df2
           pp=real(ct(i))**2 + aimag(ct(i))**2
           if(pp.gt.ppmax) then
              ppmax=pp
              dfpk=f
           endif
        enddo

        zsum=0.
        do j=1,NN
           phi=(j-1)*twopi*dfpk*ts
           w=cmplx(cos(phi),sin(phi))
           cps=cs(i0:i0+6*nts:2*nts,j)*conjg(w)
           z=cps(id2(j))
           ct(j)=z
           zsum=zsum+z
           write(12,1042) j,id(j),id2(j),20*ps,atan2(aimag(z),real(z)),  &
                atan2(aimag(zsum),real(zsum)),zsum
1042       format(3i2,6f8.3,2f8.1)
        enddo

        phi0=atan2(aimag(zsum),real(zsum))
        zsum=0.
        do j=1,NN
           phi=(j-1)*twopi*dfpk*ts + phi0
           w=cmplx(cos(phi),sin(phi))
           nlo=0
           nhi=0
           cps=cs(i0:i0+6*nts:2*nts,j)*conjg(w)
           ps=real(cps)
           if(max(ps(1),ps(3)).ge.max(ps(0),ps(2))) nlo=1
           if(max(ps(2),ps(3)).ge.max(ps(0),ps(1))) nhi=1
           id2(j)=2*nhi+nlo
           z=cps(id2(j))
           ct(j)=z
           zsum=zsum+z
        enddo
        
        nh2=count(id.ne.id2)
        nb2=count(iand(id,1).ne.iand(id2,1)) + count(iand(id,2).ne.iand(id2,2))
        nhard1=nhard1+nh1
        nhard2=nhard2+nh2
        nbit1=nbit1+nb1
        nbit2=nbit2+nb2

        fdiff=1500.0+freq - f0
        write(13,1040)  snrdb,snr2500,f0,fdiff,width,nh1,nb1,nh2,nb2
1040    format(2f7.1,f9.2,f7.2,f6.1,2(i8,i6))
40      continue
     enddo

     ser1=float(nhard1)/(NN*iters)
     ser2=float(nhard2)/(NN*iters)
     ber1=float(nbit1)/(2*NN*iters)
     ber2=float(nbit2)/(2*NN*iters)
     write(*,1050)  snrdb,nhard1,nbit1,ser1,ber1,nhard2,nbit2,ser2,ber2
     write(14,1050) snrdb,nhard1,nbit1,ser1,ber1,nhard2,nbit2,ser2,ber2
1050 format(f6.1,2(2i5,2f8.4))
  enddo
  write(*,1060) NN*iters,2*NN*iters
1060 format(59('-')/'Max:  ',2i5)

999 end program fsk4sim
