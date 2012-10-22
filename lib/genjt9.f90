subroutine genjt9(message,msgsent,i4tone)

! Encodes a JT9 message and returns msgsent, the message as it will
! be decoded, and an integer array i4tone(85) of 9-FSK tone values 
! in the range 0-8.  

  character*22 message                    !Message to be generated
  character*22 msgsent                    !Message as it will be received
  integer*4 i4Msg6BitWords(13)            !72-bit message as 6-bit words
  integer*1 i1Msg8BitBytes(13)            !72 bits and zero tail as 8-bit bytes
  integer*1 i1EncodedBits(207)            !Encoded information-carrying bits
  integer*1 i1ScrambledBits(207)          !Encoded bits after interleaving
  integer*4 i4DataSymbols(69)             !Data symbols (values 0-7)
  integer*4 i4GrayCodedSymbols(69)        !Gray-coded symbols (values 0-7)
  integer*4 i4tone(85)                    !Tone #s, data and sync (values 0-8)
  include 'jt9sync.f90'
  save

  call packmsg(message,i4Msg6BitWords)    !Pack message into 12 6-bit bytes
  call unpackmsg(i4Msg6BitWords,msgsent)  !Unpack to get msgsent
  call entail(i4Msg6BitWords,i1Msg8BitBytes)  !Add tail, convert to 8-bit bytes
  nsym2=206
  call encode232(i1Msg8BitBytes,nsym2,i1EncodedBits)   !Encode K=32, r=1/2
  call interleave9(i1EncodedBits,1,i1ScrambledBits)    !Interleave the bits
  call packbits(i1ScrambledBits,nsym2,3,i4DataSymbols) !Pack 3-bits into words
  call graycode(i4DataSymbols,69,1,i4GrayCodedSymbols) !Apply Gray code

! Insert sync symbols at ntone=0 and add 1 to the data-tone numbers.
  j=0
  do i=1,85
     if(isync(i).eq.1) then
        i4tone(i)=0
     else
        j=j+1
        i4tone(i)=i4GrayCodedSymbols(j)+1
     endif
  enddo

  return
end subroutine genjt9
