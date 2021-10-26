program ft8q3

! Test q3-style decodes for FT8.

  use packjt77
  parameter(NN=79,NSPS=32)
  parameter(NWAVE=NN*NSPS)               !2528
  parameter(NZ=3200,NLAGS=NZ-NWAVE)
  character arg*12
  character msg37*37
  character c77*77
  complex cwave(0:NWAVE-1)
  complex cd(0:NZ-1)
  complex z
  real xjunk(NWAVE)
  real ccf(0:NLAGS-1)
  integer itone(NN)
  integer*1 msgbits(77)

! Get command-line argument(s)
  nargs=iargc()
  if(nargs.ne.3) then
     print*,'Usage:    ft8q3 DT f0 "message"'
     go to 999
  endif
  call getarg(1,arg)
  read(arg,*) xdt                        !Time offset from nominal (s)
  call getarg(2,arg)
  read(arg,*) f0                         !Frequency (Hz)
  call getarg(3,msg37)                   !Message to be transmitted

  fs=200.0                               !Sample rate (Hz)
  dt=1.0/fs                              !Sample interval (s)
  bt=2.0                         

! Source-encode, then get itone()
  i3=-1
  n3=-1
  call pack77(msg37,i3,n3,c77)
  call genft8(msg37,i3,n3,msgsent37,msgbits,itone)
! Generate complex cwave
  call gen_ft8wave(itone,NN,NSPS,bt,fs,f0,cwave,xjunk,1,NWAVE)

  do i=0,NZ-1
     read(40,3040) cd(i)
3040 format(17x,2f10.3)
  enddo

  lagbest=-1
  ccfbest=0.
  nsum=32*2
  do lag=0,nlags-1
     z=0.
     s=0.
     do i=0,NWAVE-1
        z=z + cd(i+lag)*conjg(cwave(i))
        if(mod(i,nsum).eq.nsum-1 .or. i.eq.NWAVE-1) then
           s=s + abs(z)
           z=0.
        endif
     enddo
!     ccf(lag)=abs(z)
     ccf(lag)=s
     write(42,3042) lag-100,(lag-100)/200.0,ccf(lag)
3042 format(i5,f10.3,f10.0)
     if(ccf(lag).gt.ccfbest) then
        ccfbest=ccf(lag)
        lagbest=lag
     endif
  enddo

  z=0.
  do i=0,NWAVE-1
     z=z + cd(i+lagbest)*conjg(cwave(i))
     if(mod(i,32).eq.31) then
        amp=abs(z)**2
        pha=atan2(aimag(z),real(z))
        j=i/32
        write(43,3043) z,j,amp,pha
3043    format(2f12.0,i6,f12.0,f12.6)
     endif
  enddo

999 end program ft8q3
