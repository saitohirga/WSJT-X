subroutine genjt9(message,minutes,lwave,msgsent,d7,iwave,nwave)

! Encodes a "JT9-minutes" message and returns array d7(81) of tone
! values in the range 0-8.  If lwave is true, also returns a generated
! waveform in iwave(nwave), at 12000 samples per second.

  parameter (NMAX=1800*12000)   !Max length of wave file
  character*22 message          !Message to be generated
  character*22 msgsent          !Message as it will be received
  character*3 cok
  real*8 dt,phi,f,f0,dfgen,dphi,twopi
  integer*2 iwave(NMAX)         !Generated wave file
  integer   d0(14)              !72-bit message + 12-bit CRC, as 6-bit bytes
  integer*1 d1(84)              !72+12 = 84 single bits 
  integer   d2(11)              !72+12 bits, as 8-bit words
  integer*1 d3(11)              !72+12 bits, as 8-bit bytes
  integer*1 d4(198)             !Encoded information-carrying bits
  integer*1 d5(198)             !Bits from d4, after interleaving
  integer*1 d6(66)              !Symbols from d5, values 0-7
  integer*1 d7(66)              !Gray-coded symbols, values 0-7
  integer*1 d8(81)              !Channel symbols including sync, values 0-8

  logical lwave
  integer isync(15)
  data isync/1,6,11,16,21,26,31,39,45,51,57,63,69,75,81/
  data twopi/6.283185307179586476d0/
  save

  call chkmsg(message,cok,nspecial,flip)
  call packmsg(message,d0)            !Pack message into 12 6-bit bytes
  d0(11)=0                            !### Temporary CRC=0 ###
  d0(12)=0
  call unpackbits(d0,14,6,d1)         !Unpack into 84 bits
  nbits=84
  call packbits(d1,nbits,8,d2)        !Pack into 11 8-bit words
  nbytes=(nbits+7)/8
  do i=1,nbytes
     if(d2(i).lt.128) d3(i)=d2(i)
     if(d2(i).ge.128) d3(i)=d2(i)-256
  enddo

  call enc216(d3,nbits,d4,nsym2,16,2)   !Convolutional code, K=16, r=1/2
! NB: Should give nsym2 = (72+12+15)*2 = 198

!  call interleavejt9(d4,1,d5)
  d5=d4                             !### TEMP ###

  call packbits(d5,nsym2,3,d6)
!  call graycode(d6,nsym2,1,d7)

! Now insert sync symbols and add 1 to the tone numbers.

  nwave=0

  if(lwave) then
     nsps1=0
     if(minutes.eq.1)  nsps1=7168
     if(minutes.eq.2)  nsps1=16000
     if(minutes.eq.5)  nsps1=42336
     if(minutes.eq.10) nsps1=86400
     if(minutes.eq.30) nsps1=262144
     if(nsps1.eq.0) stop 'Bad value for minutes in genjt9.'

! Set up necessary constants
     dt=1.d0/12000.d0
     f0=1500.d0
     dfgen=12000.d0/nsps1
     phi=0.d0
     i=0
     k=0
     do j=1,81
        f=f0 +d7(j)*dfgen
        dphi=twopi*dt*f
        do i=1,nsps1
           phi=phi+dphi
           if(phi.gt.twopi) phi=phi-twopi
           xphi=phi
           k=k+1
           iwave(k)=32767.0*sin(xphi)
        enddo
     enddo
     nwave=81*nsps1
  endif
  call unpackmsg(dgen,msgsent)

  return
end subroutine genjt9
