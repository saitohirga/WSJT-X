program JTMSKfer

! Measure the frame error rate (fer) of the rate 1/2, K=13 conv. code with 
! coherent BPSK, Viterbi decoding, perfect sync. The results are to be 
! compared with LDPC fer's produced by the routines in the ldpc sandbox folder.
! These coherent BPSK results will not correspond to JTMSK.

  use iso_c_binding, only: c_loc,c_size_t
  use hashing
  use packjt
  character msg*22,decoded*22,msgtype*13
  integer*4 i4tone(234)                   !Channel symbols (values 0-1)
  integer*1 e1(201)
  integer*4 r1(201)
  real rd(201), tmp
  integer*1, target :: d8(13)
  integer mettab(0:255,0:1)               !Metric table for BPSK modulation
  integer*1 i1hash(4)
  integer*4 i4Msg6BitWords(12)            !72-bit message as 6-bit words
  character*72 c72
!  real*8 twopi,dt,f0,f1,f,phi,dphi
  real xp(29)
  equivalence (ihash,i1hash)
  data xp/0.500000, 0.401241, 0.309897, 0.231832, 0.168095,    &
          0.119704, 0.083523, 0.057387, 0.039215, 0.026890,    &
          0.018084, 0.012184, 0.008196, 0.005475, 0.003808,    &
          0.002481, 0.001710, 0.001052, 0.000789, 0.000469,    &
          0.000329, 0.000225, 0.000187, 0.000086, 0.000063,    &
          0.000017, 0.000091, 0.000032, 0.000045/
  include 'testmsg.f90'

  nmsg=1

! Get the metric table
  bias=0.0
  scale=20.0
  xln2=log(2.0)
  do i=128,156
     x0=log(max(0.0001,2.0*xp(i-127)))/xln2
     x1=log(max(0.001,2.0*(1.0-xp(i-127))))/xln2
     mettab(i,0)=nint(scale*(x0-bias))
     mettab(i,1)=nint(scale*(x1-bias))
     mettab(256-i,0)=mettab(i,1)
     mettab(256-i,1)=mettab(i,0)
  enddo
  do i=157,255
     mettab(i,0)=mettab(156,0)
     mettab(i,1)=mettab(156,1)
     mettab(256-i,0)=mettab(i,1)
     mettab(256-i,1)=mettab(i,0)
  enddo

  rdscale=2.0 ! empirically optiized
  ntrials=1000000
  rate=72.0/198.0
  msg="123"
!  call sgran()

  do idb=0,10
    db=idb/2.0-0.5   ! Eb/N0=1/(2*R*sigma^2), so sigma= sqrt( 1/(2*R*Eb/N0) )
    sigma=1/sqrt( 2*rate*(10**(db/10.0)) )

     call fmtmsg(msg,iz)                !To upper case, collapse multiple blanks
     ichk=0
     call genmsk(msg,ichk,decoded,i4tone,itype)   !Encode message into tone #s
     msgtype=""
     if(itype.eq.1) msgtype="Std Msg"
     if(itype.eq.2) msgtype="Type 1 prefix"
     if(itype.eq.3) msgtype="Type 1 suffix"
     if(itype.eq.4) msgtype="Type 2 prefix"
     if(itype.eq.5) msgtype="Type 2 suffix"
     if(itype.eq.6) msgtype="Free text"

! Extract the data symbols, skipping over sync and parity bits
     n1=35
     n2=69
     n3=94

     r1(1:n1)=i4tone(11+1:11+n1)
     r1(n1+1:n1+n2)=i4tone(23+n1+1:23+n1+n2)
     r1(n1+n2+1:n1+n2+n3)=i4tone(35+n1+n2+1:35+n1+n2+n3)

   ngood=0      ! decoded = msg
   ngoodhash=0  ! will include undetected errors plus actual good ones

   do itrial=1,ntrials
     do i=1,n1+n2+n3
       tmp=( 2.0 * ( r1(i)-0.5 ) + sigma*gran() )*rdscale
       if( tmp .lt. 0 ) then
         rd(i)=min(127.0,-tmp)
       elseif( tmp .gt.0 ) then
         rd(i)=max(-tmp,-127.0)
       endif
     enddo

     j=0
     do i=1,99
        j=j+1
        e1(j)=rd(i)
        j=j+1
        e1(j)=rd(i+99)
     enddo

     nb1=87
     call vit213(e1,nb1,mettab,d8,metric)

     igoodhash=0
     ihash=nhash(c_loc(d8),int(9,c_size_t),146)
     ihash=2*iand(ihash,32767)
     decoded="                      "
     if(d8(10).eq.i1hash(2) .and. d8(11).eq.i1hash(1)) then
        igoodhash=1
        write(c72,1012) d8(1:9)
1012    format(9b8.8)
        read(c72,1014) i4Msg6BitWords
1014    format(12b6.6)
        call unpackmsg(i4Msg6BitWords,decoded)      !Unpack to get msgsent
     endif

     if( igoodhash .eq. 1) ngoodhash=ngoodhash+1
     if( decoded .eq. msg ) ngood=ngood+1

  enddo

  write(*,1023) db,sigma,ntrials,ngood,ngoodhash-ngood
1023 format("db:",f6.2,"  sigma:",f6.2,"  ntot:",i8," good:",i8," undet:",i8)
enddo
999 end program JTMSKfer
