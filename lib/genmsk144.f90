subroutine genmsk144(msg0,ichk,msgsent,i4tone,itype)

!!!!!!!!!!!!!!!!!! Experimental small blocklength ldpc version
! s8 + 48bits + s8 + 80 bits = 144 bits (72ms message duration)
!
! Encode a JTMSK message
! Input:
!   - msg0     requested message to be transmitted
!   - ichk     if ichk=1, return only msgsent
!              if ichk.ge.10000, set imsg=ichk-10000 for short msg
!   - msgsent  message as it will be decoded
!   - i4tone   array of audio tone values, 0 or 1
!   - itype    message type 
!                 1 = standard message  "Call_1 Call_2 Grid/Rpt"
!                 2 = type 1 prefix
!                 3 = type 1 suffix
!                 4 = type 2 prefix
!                 5 = type 2 suffix
!                 6 = free text (up to 13 characters)
!                 7 = short message     "<Call_1 Call2> Rpt"

  use iso_c_binding, only: c_loc,c_size_t
  use packjt
  use hashing
  character*85 pchk_file,gen_file
  character*22 msg0
  character*22 message                    !Message to be generated
  character*22 msgsent                    !Message as it will be received
  integer*4 i4Msg6BitWords(13)            !72-bit message as 6-bit words
  integer*4 i4tone(144)                   !
  integer*1, target:: i1Msg8BitBytes(10)  !80 bits represented in 10 bytes 
  integer*1 codeword(128)                 !Encoded bits before re-ordering
  integer*1 msgbits(80)                   !72-bit message + 8-bit hash
  integer*1 reorderedcodeword(128)        !Odd bits first, then even
  integer*1 bitseq(144)                   !Tone #s, data and sync (values 0-1)
  integer*1 i1hash(4)
  integer*1 b7(7)
  integer*1 s8(8)
  integer*1 b11(11)
  integer*1 b13(13)
  real*8 pp(12)
  real*8 xi(864),xq(864),pi,twopi,phi,dphi
  real waveform(864)
  data b7/1,1,1,0,0,1,0/
  data s8/0,1,1,1,0,0,1,0/
  data b11/1,1,1,0,0,0,1,0,0,1,0/         !Barker 11 code
  data b13/1,1,1,1,1,0,0,1,1,0,1,0,1/     !Barker 13 code
  equivalence (ihash,i1hash)
  logical first
  data first/.true./
  save

  if( first ) then
    first=.false.
    nsym=128
!! Fix this
    pchk_file="/Users/sfranke/Builds/wsjtx_install/peg-128-80-reg3.pchk"
    gen_file="/Users/sfranke/Builds/wsjtx_install/peg-128-80-reg3.gen"
    call init_ldpc(trim(pchk_file)//char(0),trim(gen_file)//char(0))  
    pi=4.*atan(1.0)
    twopi=8.*atan(1.0)
    do i=1,12
      pp(i)=sin( (i-1)*pi/12 )
    enddo
  endif

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

     if(message(1:1).eq.'<') then
        call genmsk_short(message,msgsent,ichk,i4tone,itype)
        if(itype.lt.0) go to 999
        i4tone(36)=-35
        go to 999
     endif

     call packmsg(message,i4Msg6BitWords,itype)  !Pack into 12 6-bit bytes
     call unpackmsg(i4Msg6BitWords,msgsent)      !Unpack to get msgsent
     if(ichk.eq.1) go to 999
     i4=0
     ik=0
     im=0
     do i=1,12
       nn=i4Msg6BitWords(i)
       do j=1, 6
         ik=ik+1
         i4=i4+i4+iand(1,ishft(nn,j-6))
         i4=iand(i4,255)
         if(ik.eq.8) then
           im=im+1
!           if(i4.gt.127) i4=i4-256
           i1Msg8BitBytes(im)=i4
           ik=0
         endif
       enddo
     enddo

     ihash=nhash(c_loc(i1Msg8BitBytes),int(9,c_size_t),146)
     ihash=2*iand(ihash,32767)                   !Generate the 8-bit hash
     i1Msg8BitBytes(10)=i1hash(1)                !CRC to byte 10

     mbit=0
     do i=1, 10
       i1=i1Msg8BitBytes(i)
         do ibit=1,8
           mbit=mbit+1
           msgbits(mbit)=iand(1,ishft(i1,ibit-8))
         enddo
     enddo

     call ldpc_encode(msgbits,codeword)

! Reorder the bits.
     reorderedcodeword(1:64)=codeword(1:127:2)
     reorderedcodeword(65:128)=codeword(2:128:2)

!Create 144-bit channel vector:
!8-bit sync word + 48 bits + 8-bit sync word + 80 bits
     bitseq=0 
     bitseq(1:8)=s8
     bitseq(9:56)=reorderedcodeword(1:48)
     bitseq(57:64)=s8
     bitseq(65:144)=reorderedcodeword(49:128)
     bitseq=2*bitseq-1

     xq(1:6)=bitseq(1)*pp(7:12)   !first bit is mapped to 1st half-symbol on q
     do i=1,71
       is=(i-1)*12+7
       xq(is:is+11)=bitseq(2*i+1)*pp
     enddo 
     xq(864-5:864)=bitseq(1)*pp(1:6)   !last half symbol
     do i=1,72                                    
       is=(i-1)*12+1
       xi(is:is+11)=bitseq(2*i)*pp
     enddo

! Map I and Q  to tones. 
    i4tone=0 
    do i=1,72
      i4tone(2*i-1)=(bitseq(2*i)*bitseq(2*i-1)+1)/2;
      i4tone(2*i)=-(bitseq(2*i)*bitseq(mod(2*i,144)+1)-1)/2;
    enddo
  endif

! Flip polarity
  i4tone=-i4tone+1

999 return
end subroutine genmsk144
