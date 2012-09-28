subroutine genjt9(message,minutes,lwave,msgsent,d8,iwave,nwave)

! Encodes a "JT9-minutes" message and returns array d7(85) of tone
! values in the range 0-8.  If lwave is true, also returns a generated
! waveform in iwave(nwave), at 12000 samples per second.

  parameter (NMAX=1800*12000)   !Max length of wave file
  character*22 message          !Message to be generated
  character*22 msgsent          !Message as it will be received
  real*8 dt,phi,f,f0,dfgen,dphi,twopi
  integer*2 iwave(NMAX)         !Generated wave file

  integer*4 d0(12)              !72-bit message as 6-bit words
  integer*1 d1(72)              !72 single bits 
  integer*4 d2(9)               !72 bits as 8-bit words
  integer*1 d3(9)               !72 bits as 8-bit bytes
  integer*1 d4(206)             !Encoded information-carrying bits
  integer*1 d5(206)             !Bits from d4, after interleaving
  integer*4 d6(69)              !Symbols from d5, values 0-7
  integer*4 d7(69)              !Gray-coded symbols, values 0-7
  integer*4 d8(85)              !Channel symbols including sync, values 0-8

  logical lwave
  integer isync(85)
  data isync/                                    &
       1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,  &
       1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,0,0,0,1,0,  &
       0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,  &
       0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,  &
       1,0,0,0,1/
  data twopi/6.283185307179586476d0/
  save

  call packmsg(message,d0)            !Pack message into 12 6-bit bytes
  call unpackbits(d0,12,6,d1)         !Unpack into 72 bits

  nbits=72
  nbytes=9
  call packbits(d1,nbits,8,d2)        !Pack into 9 8-bit words
  do i=1,9
     if(d2(i).lt.128) d3(i)=d2(i)
     if(d2(i).ge.128) d3(i)=d2(i)-256
  enddo

  call encode232(d3,nbytes,d4)        !Convolutional code, K=32, r=1/2
  nsym2=206
  call interleave9(d4,1,d5)
  call packbits(d5,nsym2,3,d6)
  call graycode(d6,69,1,d7)

! Insert sync symbols (ntone=0) and add 1 to the data-tone numbers.
  j=0
  do i=1,85
     if(isync(i).eq.1) then
        d8(i)=0
     else
        j=j+1
        d8(i)=d7(j)+1
     endif
  enddo

  nwave=0

  if(lwave) then
     nsps=0
     if(minutes.eq.1)  nsps=6912
     if(minutes.eq.2)  nsps=15360
     if(minutes.eq.5)  nsps=40960
     if(minutes.eq.10) nsps=82944
     if(minutes.eq.30) nsps=250880
     if(nsps.eq.0) stop 'Bad value for minutes in genjt9.'

! Set up necessary constants
     dt=1.d0/12000.d0
     f0=1500.d0
     dfgen=12000.d0/nsps
     phi=0.d0
     i=0
     k=0
     do j=1,85
        f=f0 +d7(j)*dfgen
        dphi=twopi*dt*f
        do i=1,nsps
           phi=phi+dphi
           if(phi.gt.twopi) phi=phi-twopi
           xphi=phi
           k=k+1
           iwave(k)=32767.0*sin(xphi)
        enddo
     enddo
     nwave=85*nsps
  endif

  call unpackmsg(d0,msgsent)

  return
end subroutine genjt9
