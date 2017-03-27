program fsk4sim

  use wavhdr
  parameter (NR=4)                      !Ramp up, ramp down
  parameter (NS=12)                     !Sync symbols (2 @ Costas 4x4)
  parameter (ND=84)                     !Data symbols: LDPC (168,84), r=1/2
  parameter (NN=NR+NS+ND)               !Total symbols (100)
  parameter (NSPS=2688)                 !Samples per symbol at 12000 sps
  parameter (NZ=NSPS*NN)                !Samples in waveform (258048)
  parameter (NFFT=512*1024)
  parameter (NSYNC=NS*NSPS)

  type(hdr) header                      !Header for .wav file
  character*8 arg
  complex c(0:NFFT-1)                   !Complex waveform
  complex cf(0:NFFT-1)
  complex cs(0:NSYNC-1)
  complex ct(0:NSPS-1)
  complex csync(0:NSYNC-1)
  complex z
  real*8 twopi,dt,fs,baud,f0,dphi,phi
  real tmp(NN)                          !For generating random data
  real s(0:NFFT-1)
!  real s2(0:NFFT-1)
  real xnoise(NZ)                       !Generated random noise
  real ps(0:3)
  integer*2 iwave(NZ)                   !Generated waveform
  integer id(NN)                        !Encoded 2-bit data (values 0-3)
  integer icos4(4)                      !4x4 Costas array
  data icos4/0,1,3,2/

  nargs=iargc()
  if(nargs.ne.3) then
     print*,'Usage: fsk8sim f0 iters snr'
     go to 999
  endif
  call getarg(1,arg)
  read(arg,*) f0                        !Low tone frequency
  call getarg(2,arg)
  read(arg,*) iters
  call getarg(3,arg)
  read(arg,*) snrdb


  twopi=8.d0*atan(1.d0)
  fs=12000.d0
  dt=1.0/fs
  ts=NSPS*dt
  baud=1.d0/ts
  txt=NZ*dt

  isna=-20
  isnb=-30
  if(snrdb.ne.0.0) then
     isna=nint(snrdb)
     isnb=isna
  endif
  do isnr=isna,isnb,-1
  snrdb=isnr

  bandwidth_ratio=2500.0/6000.0
  sig=sqrt(2*bandwidth_ratio) * 10.0**(0.05*snrdb)
  if(snrdb.gt.90.0) sig=1.0
  header=default_header(12000,NZ)
  open(10,file='000000_0001.wav',access='stream',status='unknown')
  
  nsyncerr=0
  nharderr=0
  nbiterr=0
  do iter=1,iters
  id=0
  call random_number(tmp)
  where(tmp.ge.0.25 .and. tmp.lt.0.50) id=1
  where(tmp.ge.0.50 .and. tmp.lt.0.75) id=2
  where(tmp.ge.0.75) id=3

  id(1:2)=icos4(3:4)                    !Ramp up
  id(45:48)=icos4                       !Costas sync
  id(49:52)=icos4                       !Costas sync
  id(53:56)=icos4                       !Costas sync
  id(NN-1:NN)=icos4(1:2)                !Ramp down

! Generate sync waveform
  phi=0.d0
  k=-1
  do j=45,56
     dphi=twopi*(id(j)*baud)*dt
     do i=1,NSPS
        k=k+1
        phi=phi+dphi
        if(phi.gt.twopi) phi=phi-twopi
        xphi=phi
        csync(k)=cmplx(cos(xphi),-sin(xphi))
     enddo
  enddo

! Generate the 4-FSK waveform
  x=0.
  c=0.
  phi=0.d0
  k=-1
  u=0.5
  do j=1,NN
     dphi=twopi*(f0 + id(j)*baud)*dt
     do i=1,NSPS
        k=k+1
        phi=phi+dphi
        if(phi.gt.twopi) phi=phi-twopi
        xphi=phi
        c(k)=cmplx(cos(xphi),sin(xphi))
     enddo
  enddo
  
  if(sig.ne.1.0) c=sig*c

  nh=NFFT/2
  df=12000.0/NFFT
  s=0.
  cf=c
  call four2a(cf,NFFT,1,-1,1)                !Transform to frequency domain

  flo=f0-baud
  fhi=f0+4*baud
  do i=0,NFFT-1                              !Remove spectral sidelobes
     f=i*df
     if(i.gt.nh) f=(i-nfft)*df
     if(f.le.flo .or. f.ge.fhi) cf(i)=0.
     s(i)=s(i) + real(cf(i))**2 + aimag(cf(i))**2
  enddo

!  s2=cshift(s,nh)
!  s2=s2/maxval(s2)
!  do i=0,NFFT-1
!     f=(i-nh)*df
!     write(13,1000) f,s2(i),10.0*log10(s2(i)+1.e-12)
!1000 format(3f12.3)
!  enddo

  c=cf
  call four2a(c,NFFT,1,1,1)                  !Transform back to time domain
  c=c/nfft

  xnoise=0.
  if(snrdb.lt.90) then
     a=1.0/sqrt(2.0)
     do i=0,NZ-1
        xx=a*gran()
        yy=a*gran()
        c(i)=c(i) + cmplx(xx,yy)         !Scale signal and add noise
     enddo
  endif

  fac=32767.0
  rms=100.0
  if(snrdb.ge.90.0) iwave(1:NZ)=nint(fac*aimag(c(0:NZ-1)))
  if(snrdb.lt.90.0) iwave(1:NZ)=nint(rms*aimag(c(0:NZ-1)))
  call set_wsjtx_wav_params(14.0,'JT65    ',1,30,iwave)
  write(10) header,iwave                  !Save the .wav file

!  do i=0,NZ-1
!     a=abs(c(i))
!     j=mod(i,NSPS)
!     write(14,1010) i*dt/ts,c(i),a
!1010 format(4f12.6)
!  enddo

  ppmax=0.
  fpk=-99.
  xdt=-99.
  do j4=-40,40
     ia=(44+0.25*j4)*NSPS
     ib=ia+NSYNC-1
     cs=csync*c(ia:ib)
     call four2a(cs,NSYNC,1,-1,1)                !Transform to frequency domain
     df1=12000.0/NSYNC
     fac=1.e-6
     do i=0,NSYNC/2
        pp=fac*(real(cs(i))**2 + aimag(cs(i))**2)
        if(pp.gt.ppmax) then
           fpk=i*df1
           xdt=0.25*j4*ts
           ppmax=pp
        endif
!        if(j4.eq.0) then
!           f=i*df1
!           write(16,1030) f,pp,10.0*log10(pp)
!1030       format(3f15.3)
!        endif
     enddo
  enddo

  if(xdt.ne.0.0 .or. fpk.ne.1500.0) nsyncerr=nsyncerr+1
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
!     if(ps(1)+ps(3).ge.ps(0)+ps(2)) nlo=1
!     if(ps(2)+ps(3).ge.ps(0)+ps(1)) nhi=1

     if(nlo.ne.iand(id(j),1)) nbiterr=nbiterr+1
     if(nhi.ne.iand(id(j)/2,1)) nbiterr=nbiterr+1

     if(ipk.ne.id(j)) nharderr=nharderr+1
     write(17,1040) j,ps,ipk,id(j),2*nhi+nlo,nhi,nlo,nbiterr
1040 format(i3,4f12.1,6i4)
  enddo
  enddo

  fsyncerr=float(nsyncerr)/iters
  ser=float(nharderr)/(NN*iters)
  ber=float(nbiterr)/(2*NN*iters)
  write(*,1050) snrdb,nsyncerr,nharderr,nbiterr,fsyncerr,ser,ber
  write(18,1050) snrdb,nsyncerr,nharderr,nbiterr,fsyncerr,ser,ber
1050 format(f6.1,3i6,3f10.6)
  enddo

999 end program fsk4sim
