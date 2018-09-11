!
! Simulator for terminated convolutional codes (so, far, only rate 1/2)
! BPSK on AWGN Channel
!
! Hybrid decoder - Fano Sequential Decoder and Ordered Statistics Decoder (OSD)a
!
program tccsim

  parameter (N=162,K=50) 
  integer*1 gen(K,N)
  integer*1 gg(64)
  integer*1 mbits(50),mbits2(50)
  integer*4 mettab(-128:127,0:1)

  parameter (NSYM=162)
  parameter (MAXSYM=162)
  character*12 arg
  character*22 msg,msg2
  integer*1 data0(13)
  integer*1 data1(13)
  integer*1 dat(206)
  integer*1 softsym(162)
  integer*1 apmask(162),cw0(162),cw(162)
  real*4    xx0(0:255)
  real      ss(162)

  character*64 g    ! Interleaved polynomial coefficients
  data g/'1101010010001100101001011101100001000000100111100010010010111111'/

  data xx0/                                                      & !Metric table
        1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,  &
        1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,  &
        1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,  &
        1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,  &
        1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,  &
        1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,  &
        0.988, 1.000, 0.991, 0.993, 1.000, 0.995, 1.000, 0.991,  &
        1.000, 0.991, 0.992, 0.991, 0.990, 0.990, 0.992, 0.996,  &
        0.990, 0.994, 0.993, 0.991, 0.992, 0.989, 0.991, 0.987,  &
        0.985, 0.989, 0.984, 0.983, 0.979, 0.977, 0.971, 0.975,  &
        0.974, 0.970, 0.970, 0.970, 0.967, 0.962, 0.960, 0.957,  &
        0.956, 0.953, 0.942, 0.946, 0.937, 0.933, 0.929, 0.920,  &
        0.917, 0.911, 0.903, 0.895, 0.884, 0.877, 0.869, 0.858,  &
        0.846, 0.834, 0.821, 0.806, 0.790, 0.775, 0.755, 0.737,  &
        0.713, 0.691, 0.667, 0.640, 0.612, 0.581, 0.548, 0.510,  &
        0.472, 0.425, 0.378, 0.328, 0.274, 0.212, 0.146, 0.075,  &
        0.000,-0.079,-0.163,-0.249,-0.338,-0.425,-0.514,-0.606,  &
       -0.706,-0.796,-0.895,-0.987,-1.084,-1.181,-1.280,-1.376,  &
       -1.473,-1.587,-1.678,-1.790,-1.882,-1.992,-2.096,-2.201,  &
       -2.301,-2.411,-2.531,-2.608,-2.690,-2.829,-2.939,-3.058,  &
       -3.164,-3.212,-3.377,-3.463,-3.550,-3.768,-3.677,-3.975,  &
       -4.062,-4.098,-4.186,-4.261,-4.472,-4.621,-4.623,-4.608,  &
       -4.822,-4.870,-4.652,-4.954,-5.108,-5.377,-5.544,-5.995,  &
       -5.632,-5.826,-6.304,-6.002,-6.559,-6.369,-6.658,-7.016,  &
       -6.184,-7.332,-6.534,-6.152,-6.113,-6.288,-6.426,-6.313,  &
       -9.966,-6.371,-9.966,-7.055,-9.966,-6.629,-6.313,-9.966,  &
       -5.858,-9.966,-9.966,-9.966,-9.966,-9.966,-9.966,-9.966,  &
       -9.966,-9.966,-9.966,-9.966,-9.966,-9.966,-9.966,-9.966,  &
       -9.966,-9.966,-9.966,-9.966,-9.966,-9.966,-9.966,-9.966,  &
       -9.966,-9.966,-9.966,-9.966,-9.966,-9.966,-9.966,-9.966,  &
       -9.966,-9.966,-9.966,-9.966,-9.966,-9.966,-9.966,-9.966,  &
       -9.966,-9.966,-9.966,-9.966,-9.966,-9.966,-9.966,-9.966/

  bias=0.42
  scale=120
!  ndelta=nint(3.4*scale)
  ndelta=100
  ib=150
  slope=2
  do i=0,255
    mettab(i-128,0)=nint(scale*(xx0(i)-bias))
    if(i.gt.ib) mettab(i-128,0)=mettab(ib-128,0)-slope*(i-ib)
    if(i.ge.1) mettab(128-i,1)=mettab(i-128,0)
  enddo
  mettab(-128,1)=mettab(-127,1)
  
! Get command-line argument(s)
  nargs=iargc()
  if(nargs.ne.3) then
     print*,'Usage: tccsim "message" ntrials ndepth'
     go to 999
  endif
  call getarg(1,msg)                             !Get message from command line
  write(*,1000) msg
1000 format('Message: ',a22)
  call getarg(2,arg) 
  read(arg,*) ntrials 
  call getarg(3,arg) 
  read(arg,*) ndepth 

  nbits=50+31               !User bits=99, constraint length=32
  nbytes=(nbits+7)/8
  limit=20000

  data0=0
  call wqencode(msg,ntype0,data0)             !Source encoding
write(*,*) 'data0 ',data0
! Demonstrates how to create the generator matrix from a string that contains the interleaved 
! polynomial coefficients
  gen=0
  do j=1,64
    read(g(j:j),"(i1)") gg(j)  ! read polynomial coeffs from string
  enddo
  do i=1,K
    gen(i,2*(i-1)+1:2*(i-1)+64)=gg  ! fill the generator matrix with cyclic shifts of gg
  enddo

! get message bits from data0      
  nbits=0
  do i=1,7
    do ib=7,0,-1
      nbits=nbits+1
      if(nbits .le. 50) then
        mbits(nbits)=0
        if(btest(data0(i),ib)) mbits(nbits)=1
      endif
    enddo
  enddo

  write(*,*) 'Source encoded message bits: '
  write(*,'(6(8i1,1x),2i1)') mbits

! Encode message bits using the generator matrix, generating a 162-bit codeword.
  cw0=0
  do i=1,50
    if(mbits(i).eq.1) cw0=mod(cw0+gen(i,:),2)
  enddo

  write(*,*) 'Codeword from generator matrix: '
  write(*,'(162i1)') cw0
 
!  call encode232(data0,nbytes,dat)     !Convolutional encoding
!  write(*,*) 'Codeword from encode232: '
!  write(*,'(162i2)') dat

!  call inter_mept(dat,1)                      !Interleaving

! Here, we have channel symbols.

!  call inter_mept(dat,-1)                     !Remove interleaving

  call init_random_seed()
  call sgran()

  do isnr=10,-20,-1
    sigma=1/sqrt(2*(10**((isnr/2.0)/10.0)))
    ngood=0
    nbad=0
    do i=1,ntrials 
      do j=1,162
        ss(j)=-(2*cw0(j)-1)+sigma*gran()           !Simulate soft symbols
      enddo

      rms=sqrt(sum(ss**2))
      ss=100*ss/rms
      where(ss>127.0) ss=127.0
      where(ss<-127.0) ss=-127.0
      softsym=ss

! Call the sequential (Fano algorithm) decoder
      nbits=50+31
!      call fano232(softsym,nbits,mettab,ndelta,limit,data1,ncycles,metric,nerr)
nerr=1
      iflag=0
      nhardmin=0
      dmin=0.0

! If Fano fails, call OSD
      if(nerr.ne.0 .and. ndepth.ge.0) then 
        apmask=0
        cw=0
        call osdwspr(softsym,apmask,ndepth,cw,nhardmin,dmin)
! OSD produces a codeword, but code is not systematic
! Use Fano with hard decisions to retrieve the message from the codeword
!        cw=-(2*cw-1)*64
!        nbits=50+31
!dat=0
!dat(1:162)=cw
!        call fano232(dat,nbits,mettab,ndelta,limit,data1,ncycles,metric,nerr)
!        iflag=1
      endif
!  call wqdecode(data1,msg2,ntype1)         
!  write(*,*) msg2,iflag,nhardmin,dmin
      if(any(cw.ne.cw0)) nbad=nbad+1
      if(all(cw.eq.cw0)) ngood=ngood+1
    enddo

  write(*,'(f4.1,i8,i8)') isnr/2.0,ngood,nbad
  enddo

999 end program tccsim

#include '../wsprcode/wspr_old_subs.f90'
  
