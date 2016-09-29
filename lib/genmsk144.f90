subroutine genmsk144(msg0,mygrid,ichk,bcontest,msgsent,i4tone,itype)
! s8 + 48bits + s8 + 80 bits = 144 bits (72ms message duration)
!
! Encode an MSK144 message
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
  character*22 msg0
  character*22 message                    !Message to be generated
  character*22 msgsent                    !Message as it will be received
  character*6 mygrid,g1,g2,g3,g4
  integer*4 i4Msg6BitWords(13)            !72-bit message as 6-bit words
  integer*4 i4tone(144)                   !
  integer*1, target:: i1Msg8BitBytes(10)  !80 bits represented in 10 bytes 
  integer*1 codeword(128)                 !Encoded bits before re-ordering
  integer*1 msgbits(80)                   !72-bit message + 8-bit hash
  integer*1 bitseq(144)                   !Tone #s, data and sync (values 0-1)
  integer*1 i1hash(4)
  integer*1 s8(8)
  logical*1 bcontest
  real*8 pp(12)
  real*8 xi(864),xq(864),pi,twopi
  data s8/0,1,1,1,0,0,1,0/
  equivalence (ihash,i1hash)
  logical first,isgrid
  data first/.true./
  save

  if( first ) then
    first=.false.
    nsym=128
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
        call genmsk40(message,msgsent,ichk,i4tone,itype)
        if(itype.lt.0) go to 999
        i4tone(41)=-40
        go to 999
     endif

     if(bcontest) then
        i0=index(message,' R ') + 3
        g1=message(i0:i0+3)//'  '
        if(isgrid(g1)) then
           call grid2deg(g1,dlong,dlat)
           dlong=dlong+180.0
           if(dlong.gt.180.0) dlong=dlong-360.0
           dlat=-dlat
           call deg2grid(dlong,dlat,g2)
           message=message(1:i0-3)//g2(1:4)
        endif
     endif

     call packmsg(message,i4Msg6BitWords,itype)  !Pack into 12 6-bit bytes
     call unpackmsg(i4Msg6BitWords,msgsent)      !Unpack to get msgsent

     if(bcontest) then
        i1=index(msgsent(8:22),' ') + 8
        g3=msgsent(i1:i1+3)//'  '
        if(isgrid(g3)) then
           call azdist(mygrid,g3,0.d0,nAz,nEl,nDmiles,nDkm,nHotAz,nHotABetter)
           if(ndkm.gt.10000) then
              call grid2deg(g3,dlong,dlat)
              dlong=dlong+180.0
              if(dlong.gt.180.0) dlong=dlong-360.0
              dlat=-dlat
              call deg2grid(dlong,dlat,g4)
              msgsent=msgsent(1:i1-1)//'R '//g4(1:4)
           endif
        endif
     endif

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

     call encode_msk144(msgbits,codeword)

!Create 144-bit channel vector:
!8-bit sync word + 48 bits + 8-bit sync word + 80 bits
     bitseq=0 
     bitseq(1:8)=s8
     bitseq(9:56)=codeword(1:48)
     bitseq(57:64)=s8
     bitseq(65:144)=codeword(49:128)
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

logical function isgrid(g1)

  character*4 g1

  isgrid=g1(1:1).ge.'A' .and. g1(1:1).le.'R' .and. g1(2:2).ge.'A' .and.     &
       g1(2:2).le.'R' .and. g1(3:3).ge.'0' .and. g1(3:3).le.'9' .and.       &
       g1(4:4).ge.'0' .and. g1(4:4).le.'9'

  return
end function isgrid
