subroutine genmsk(msg0,ichk,msgsent,i4tone,itype)

! Encode a JTMSK message
! Input:
!   - msg0     requested message to be transmitted
!   - ichk     if nonzero, return only msgsent
!   - msgsent  message as it will be decoded
!   - i4tone   array of audio tone values, 0 or 1
!   - itype    message type 
!                 1 = standard message  <call1> <call2> <grid/rpt>
!                 2 = type 1 prefix
!                 3 = type 1 suffix
!                 4 = type 2 prefix
!                 5 = type 2 suffix
!                 6 = free text (up to 13 characters)

  use iso_c_binding, only: c_loc,c_size_t
  use packjt
  use hashing
  character*22 msg0
  character*22 message                    !Message to be generated
  character*22 msgsent                    !Message as it will be received
  integer*4 i4Msg6BitWords(13)            !72-bit message as 6-bit words
  integer*1, target:: i1Msg8BitBytes(13)  !72 bits and zero tail as 8-bit bytes
  integer*1 e1(198)                       !Encoded bits before re-ordering
  integer*1 i1EncodedBits(198)            !Encoded information-carrying bits
  integer i4tone(234)                     !Tone #s, data and sync (values 0-1)
  integer*1 i1hash(4)
  integer b11(11)
  data b11/1,1,1,0,0,0,1,0,0,1,0/         !Barker 11 code
  equivalence (ihash,i1hash)
  save

  if(msg0(1:1).eq.'@') then                    !Generate a fixed tone
     read(msg0(2:5),*,end=1,err=1) nfreq       !at specified frequency
     go to 2
1    nfreq=1000
2    i4tone(1)=nfreq
  else
     message=msg0
     do i=1,22
        if(ichar(message(i:i)).eq.0) then
           message(i:)='                      '
           exit
        endif
     enddo

     do i=1,22                               !Strip leading blanks
        if(message(1:1).ne.' ') exit
        message=message(i+1:)
     enddo

     call packmsg(message,i4Msg6BitWords,itype)  !Pack into 12 6-bit bytes
     call unpackmsg(i4Msg6BitWords,msgsent)      !Unpack to get msgsent
     if(ichk.ne.0) go to 999
     call entail(i4Msg6BitWords,i1Msg8BitBytes)  !Add tail, make 8-bit bytes
     ihash=nhash(c_loc(i1Msg8BitBytes),int(9,c_size_t),146)
     ihash=2*iand(ihash,32767)                   !Generate the CRC
     i1Msg8BitBytes(10)=i1hash(2)                !CRC to bytes 10 and 11
     i1Msg8BitBytes(11)=i1hash(1)

     nsym=198                                    !(72+12+15)*2 = 198
     kc=13
     nc=2
     nbits=87
     call enc213(i1Msg8BitBytes,nbits,e1,nsym,kc,nc) !Encode the message

     j=0
     do i=1,nsym/2                               !Reorder the encoded bits
        j=j+1
        i1EncodedBits(j)=e1(2*i-1)
        i1EncodedBits(j+99)=e1(2*i)
     enddo

! Insert three Barker 11 codes and three "even-f0-parity" bits
     i4tone=0                                    !Start with all 0's
     n1=35
     n2=69
     n3=94
     i4tone(1:11)=b11                            !11 sync bits
     i4tone(11+1:11+n1)=i1EncodedBits(1:n1)      !n1 data bits
     nn1=count(i4tone(11+1:11+n1).eq.0)          !Count the 0's
     if(mod(nn1,2).eq.0) i4tone(12+n1)=1         !1 parity bit

     i4tone(13+n1:23+n1)=b11                     !11 sync bits
     i4tone(23+n1+1:23+n1+n2)=i1EncodedBits(n1+1:n1+n2) !n2 data bits
     nn2=count(i4tone(23+n1+1:23+n1+n2).eq.0)    !Count the 0's
     if(mod(nn2,2).eq.0) i4tone(24+n1+n2)=1      !1 parity bit

     i4tone(25+n1+n2:35+n1+n2)=b11               !11 sync bits
     i4tone(35+n1+n2+1:35+n1+n2+n3)=i1EncodedBits(n1+n2+1:n1+n2+n3)!n3 data bits
     nn3=count(i4tone(35+n1+n2+1:35+n1+n2+n3).eq.0) !Count the 0's
     if(mod(nn3,2).eq.0) i4tone(36+n1+n2+n3)=1      !1 parity bit
  endif

  n=count(i4tone.eq.0)
  if(mod(n,2).ne.0) stop 'Parity error in genmsk.'
     
999 return
end subroutine genmsk
