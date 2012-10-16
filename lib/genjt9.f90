subroutine genjt9(message,msgsent,d6)

! Encodes a JT9 message and returns msgsent, the message as it will
! be decoded, and an integer array d6(85) of 9-FSK tone values 
! in the range 0-8.  

  character*22 message          !Message to be generated
  character*22 msgsent          !Message as it will be received

  integer*4 d0(13)              !72-bit message as 6-bit words
  integer*1 d1(13)              !72 bits and zero tail as 8-bit bytes
  integer*1 d2(207)             !Encoded information-carrying bits
  integer*1 d3(207)             !Bits from d2, after interleaving
  integer*4 d4(69)              !Symbols from d3, values 0-7
  integer*4 d5(69)              !Gray-coded symbols, values 0-7
  integer*4 d6(85)              !Channel symbols including sync, values 0-8

  integer isync(85)             !Sync vector
  data isync/                                    &
       1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,  &
       1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,0,0,0,1,0,  &
       0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,  &
       0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,  &
       1,0,0,0,1/
  save

  call packmsg(message,d0)           !Pack message into 12 6-bit bytes
  call unpackmsg(d0,msgsent)         !Unpack d0 to get msgsent
  call entail(d0,d1)                 !Add tail, convert to 8-bit bytes
  nsym2=206
  call encode232(d1,nsym2,d2)        !Convolutional code, K=32, r=1/2
  call interleave9(d2,1,d3)          !Interleave the single bits
  call packbits(d3,nsym2,3,d4)       !Pack 3-bit groups into words

!  d5=d4
!  print*,d5
  call graycode(d4,69,1,d5)          !Apply Gray code

! Insert sync symbols (ntone=0) and add 1 to the data-tone numbers.
  j=0
  do i=1,85
     if(isync(i).eq.1) then
        d6(i)=0
     else
        j=j+1
        d6(i)=d5(j)+1
     endif
  enddo

  return
end subroutine genjt9
