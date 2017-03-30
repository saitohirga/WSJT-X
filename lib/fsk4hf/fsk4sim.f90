program fsk4sim

  use wavhdr
  parameter (NR=4)                       !Ramp up, ramp down
  parameter (NS=12)                      !Sync symbols (2 @ Costas 4x4)
  parameter (ND=84)                      !Data symbols: LDPC (168,84), r=1/2
  parameter (NN=NR+NS+ND)                !Total symbols (100)
  parameter (NSPS=2688)                  !Samples per symbol at 12000 sps
  parameter (NZ=NSPS*NN)                 !Samples in waveform (268800)
  parameter (NSYNC=NS*NSPS)              !Samples in sync waveform (32256)
  parameter (NFFT=512*1024)
  parameter (NDOWN=84)                   !Downsample factor
  parameter (NFFT2=NZ/NDOWN,NH2=NFFT2/2) !3200
  parameter (NSPSD=NFFT2/NN)             !Samples per symbol after downsample

  type(hdr) header                      !Header for .wav file
  character*8 arg
  complex c(0:NFFT-1)                   !Complex waveform
  complex cf(0:NFFT-1)
  complex cs(0:NSYNC-1)
  complex ct(0:NSPS-1)
  complex csync(0:NSYNC-1)
  complex c2(0:NFFT2-1)
  complex c2a(0:NSPSD-1)
  complex cf2(0:NFFT2-1)
  complex cx(0:3,NN)
  complex z,zpk
  logical snrtest
  real*8 twopi,dt,fs,baud,f0,dphi,phi
  real tmp(NN)                          !For generating random data
  real xnoise(0:NZ-1)                   !Generated random noise
  real s(NSYNC/2)
  real ps(0:3)
!  integer*2 iwave(NZ)                   !Generated waveform
  integer id(NN)                        !Encoded 2-bit data (values 0-3)
  integer id2(NN)                       !Decoded after downsampling
  integer icos4(4)                      !4x4 Costas array
  data icos4/0,1,3,2/,eps/1.e-8/

  nargs=iargc()
  if(nargs.ne.4) then
     print*,'Usage: fsk8sim f0 fspread iters snr'
     go to 999
  endif
  call getarg(1,arg)
  read(arg,*) f0                        !Low tone frequency
  call getarg(2,arg)
  read(arg,*) fspread
  call getarg(3,arg)
  read(arg,*) iters
  call getarg(4,arg)
  read(arg,*) snrdb

  snrtest=.false.
  if(iters.lt.0) then
     snrtest=.true.
     iters=abs(iters)
  endif

  twopi=8.d0*atan(1.d0)
  fs=12000.d0
  dt=1.0/fs
  ts=NSPS*dt
  baud=1.d0/ts
  txt=NZ*dt
  
! Generate sync waveform
  phi=0.d0
  k=-1
  do j=1,12
     n=mod(j-1,4) + 1
     dphi=twopi*(icos4(n)*baud)*dt
     do i=1,NSPS
        k=k+1
        phi=phi+dphi
        if(phi.gt.twopi) phi=phi-twopi
        xphi=phi
        csync(k)=cmplx(cos(xphi),-sin(xphi))
     enddo
  enddo
  bandwidth_ratio=2500.0/6000.0
  header=default_header(12000,NZ)

  write(*,1000) 2*ND,ND,NS,NN,NSPS,baud,txt,fspread
1000 format('LDPC('i3,',',i2,')  SyncSym:',i2,'  ChanSym:',i3,'  NSPS:',i4, &
          '  Baud:',f6.3,'  TxT:',f5.1,'  fDop:',f5.2/)
  if(snrtest) then
     write(*,1002)
1002 format(5x,'SNR test'/'Requested Measured Difference')
  else
     write(*,1004)
1004 format('  SNR    Sync  Sym1  Sym2  Bits  SyncErr   Sym1Err     BER'/   &
            60('-'))
  endif

  isna=-15
  isnb=-27
  if(snrdb.ne.0.0) then
     isna=nint(snrdb)
     isnb=isna
  endif
  do isnr=isna,isnb,-1
     snrdb=isnr
     sig=sqrt(2*bandwidth_ratio) * 10.0**(0.05*snrdb)
     if(snrdb.gt.90.0) sig=1.0
!     open(10,file='000000_0001.wav',access='stream',status='unknown')

     nsyncerr=0
     nharderr=0
     nherr=0
     nbiterr=0
     do iter=1,iters
        id=0
        if(.not.snrtest) then
           ! Generate random data        
           call random_number(tmp)
           where(tmp.ge.0.25 .and. tmp.lt.0.50) id=1
           where(tmp.ge.0.50 .and. tmp.lt.0.75) id=2
           where(tmp.ge.0.75) id=3
           id(1:2)=icos4(3:4)                    !Ramp up
           id(45:48)=icos4                       !Costas sync
           id(49:52)=icos4                       !Costas sync
           id(53:56)=icos4                       !Costas sync
           id(NN-1:NN)=icos4(1:2)                !Ramp down
        endif

        call genfsk4(id,f0,c)                    !Generate the 4-FSK waveform
        if(sig.ne.1.0) c=sig*c                   !Scale to requested SNR

        if(snrdb.lt.90) then
           do i=0,NZ-1                           !Generate gaussian noise
              xnoise(i)=gran()
           enddo
        endif
        if(fspread.gt.0.0) call dopspread(c,fspread)
        c(0:NZ-1)=real(c(0:NZ-1)) + xnoise       !Add noise to signal

!        fac=32767.0
!        rms=100.0
!        if(snrdb.ge.90.0) iwave(1:NZ)=nint(fac*aimag(c(0:NZ-1)))
!        if(snrdb.lt.90.0) iwave(1:NZ)=nint(rms*aimag(c(0:NZ-1)))
!        call set_wsjtx_wav_params(14.0,'JT65    ',1,30,iwave)
!        write(10) header,iwave                  !Save the .wav file

        ppmax=0.
        fpk=-99.
        xdt=-99.
        df1=12000.0/NSYNC
        iaa=nint(250.0/df1)
        ibb=nint(2750.0/df1)
        if(.not.snrtest) then
           do j4=-40,40
              ia=(44+0.25*j4)*NSPS
              ib=ia+NSYNC-1
              cs=csync*c(ia:ib)
              call four2a(cs,NSYNC,1,-1,1)     !Transform to frequency domain
              s=0.
              do i=iaa,ibb
                 s(i)=1.e-6*(real(cs(i))**2 + aimag(cs(i))**2)
              enddo
              
              if(j4.eq.0) then
                 do i=iaa,ibb
                    write(66,3301) i*df1,s(i)
3301                format(f10.3,2f12.6)
                 enddo
              endif

              call smo121(s,NSYNC/2)

              if(j4.eq.0) then
                 do i=iaa,ibb
                    write(67,3301) i*df1,s(i)
                 enddo
              endif

              do i=iaa,ibb                 
                 if(s(i).gt.ppmax) then
                    fpk=i*df1
                    xdt=0.25*j4*ts
                    ppmax=s(i)
                 endif
              enddo

           enddo
        endif
        if(xdt.ne.0.0 .or. fpk.ne.1500.0) nsyncerr=nsyncerr+1

! Compute spectrum again
        cf=c
        df2=12000.0/NZ
        call four2a(cf,NZ,1,-1,1)           !Transform to frequency domain

        if(snrtest) then
           width=5.0*df2 + fspread
           iz=nint(2500.0/df2) + 2
           if(iter.eq.1) then
              pnoise=0.
              psig=0.
              n=0
           endif
           do i=0,iz                        !Remove spectral sidelobes
              f=i*df2
              if(i.gt.NZ/2) f=(i-NZ)*df2
              p=1.e-6*(real(cf(i))**2 + aimag(cf(i))**2)
              if(abs(f-f0).lt.width) then
                 psig=psig+p
                 n=n+1
              else
                 pnoise=pnoise + p
              endif
           enddo
           if(iter.eq.iters) then
              db=10.0*log10(psig/pnoise)
              write(*,1010) snrdb,db,db-snrdb
1010          format(f7.1,2f9.1)
           endif
           go to 40
        endif

! Select a small frequency slice around fpk.
        cf=cf/NZ
        ib=nint(fpk/df2)+NH2
        ia=ib-NFFT2+1
        cf2=cshift(cf(ia:ib),NH2-1)
        flo=-baud
        fhi=4*baud
        do i=0,NFFT2-1
           f=i*df2
           if(i.gt.NH2) f=(i-NFFT2)*df2
           if(f.le.flo .or. f.ge.fhi) cf2(i)=0.
           s2=real(cf2(i))**2 + aimag(cf2(i))**2
           write(15,3001) f,s2,10*log10(s2+eps)
3001       format(f10.3,2f15.6)
        enddo
        
        c2=cf2
        call four2a(c2,NFFT2,1,1,1)        !Back to time domain

        fshift=NSPS*baud/NSPSD
        dt2=dt*NDOWN
        do j=1,NN
           ia=(j-1)*NSPSD
           ib=ia+NSPSD-1
           c2a=c2(ia:ib)
           call four2a(c2a,NSPSD,1,-1,1)   !To freq domain
           cx(0:3,j)=c2a(0:3)
           ipk=-1
           zpk=0.
           pmax=0.0
           do i=0,3
              if(abs(cx(i,j)).gt.pmax) then
                 ipk=i
                 zpk=cx(i,j)
                 pmax=abs(zpk)
              endif
           enddo
           id2(j)=ipk
           if(ipk.ne.id(j)) nherr=nherr+1
           write(16,3003) j,id(j),ipk,ipk-id(j),abs(zpk),      &
                atan2(aimag(zpk),real(zpk)),abs(cx(0:3,j))
3003       format(3i3,i4,6f9.3)
        enddo

        ipk=0
        do j=1,NN
           ia=(j-1)*NSPS + 1
           ib=ia+NSPS
           pmax=0.
           do i=0,3
              f=fpk + i*baud
              call tweak1(c(ia:ib),NSPS,-f,ct)
              z=sum(ct)
              ps(i)=1.e-3*(real(z)**2 + aimag(z)**2)
              if(ps(i).gt.pmax) then
                 ipk=i
                 pmax=ps(i)
              endif
           enddo

           nlo=0
           nhi=0
           if(max(ps(1),ps(3)).ge.max(ps(0),ps(2))) nlo=1
           if(max(ps(2),ps(3)).ge.max(ps(0),ps(1))) nhi=1
           if(nlo.ne.iand(id(j),1)) nbiterr=nbiterr+1
           if(nhi.ne.iand(id(j)/2,1)) nbiterr=nbiterr+1
           if(ipk.ne.id(j)) nharderr=nharderr+1
           write(17,1040) j,ps,ipk,id(j),id2(j),2*nhi+nlo,nhi,nlo,nbiterr
1040       format(i3,4f12.1,7i4)
        enddo
40      continue
     enddo

     if(.not.snrtest) then
        fsyncerr=float(nsyncerr)/iters
        ser=float(nharderr)/(NN*iters)
        ber=float(nbiterr)/(2*NN*iters)
        write(*,1050)  snrdb,nsyncerr,nharderr,nherr,nbiterr,fsyncerr,ser,ber
        write(18,1050) snrdb,nsyncerr,nharderr,nherr,nbiterr,fsyncerr,ser,ber
1050    format(f6.1,4i6,3f10.6)
     endif
  enddo
  if(.not.snrtest) write(*,1060) iters,100*iters,100*iters,200*iters
1060 format(60('-')/'Max:  ',4i6)

999 end program fsk4sim
