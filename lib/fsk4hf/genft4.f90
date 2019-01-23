subroutine genft4(msg0,ichk,msgsent,i4tone)
! s12 + 64symbols = 76 channel symbols  2.027s message duration
!
! Encode an FT4  message
! Input:
!   - msg0     requested message to be transmitted
!   - ichk     if ichk=1, return only msgsent
!              if ichk.ge.10000, set imsg=ichk-10000 for short msg
!   - msgsent  message as it will be decoded
!   - i4tone   array of audio tone values, {0,1,2,3} 

  use iso_c_binding, only: c_loc,c_size_t
  use packjt77
  character*37 msg0
  character*37 message                    !Message to be generated
  character*37 msgsent                    !Message as it will be received
  character*77 c77
  integer*4 i4tone(76)
  integer*1 codeword(128)
  integer*1 msgbits(77) 
  integer*1 s12(12)
  real*8 xi(864),xq(864),pi,twopi
  data s12/0,0,0,3,3,3,3,3,3,0,0,0/
  logical unpk77_success

  twopi=8.*atan(1.0)
  pi=twopi/2.0

  message=msg0

  do i=1, 37
     if(ichar(message(i:i)).eq.0) then
        message(i:37)=' '
        exit
     endif
  enddo
  do i=1,37                               !Strip leading blanks
     if(message(1:1).ne.' ') exit
     message=message(i+1:)
  enddo

  i3=-1
  n3=-1
  call pack77(message,i3,n3,c77)
  call unpack77(c77,0,msgsent,unpk77_success) !Unpack to get msgsent

  if(ichk.eq.1) go to 999
  read(c77,"(77i1)") msgbits
  call encode_128_90(msgbits,codeword)

! Grayscale mapping:
! bits   tone
! 00     0
! 01     1
! 11     2
! 10     3

!Create 144-bit channel vector:
  i4tone(1:12)=s12
  do i=1,64
    is=codeword(2*i)+2*codeword(2*i-1)
    if(is.le.1) i4tone(12+i)=is
    if(is.eq.2) i4tone(12+i)=3
    if(is.eq.3) i4tone(12+i)=2
  enddo

999 return
end subroutine genft4
