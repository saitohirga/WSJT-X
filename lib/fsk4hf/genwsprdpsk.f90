subroutine genwsprdpsk(msg,msgsent,imsgde)

! Encode a WSPRDPSK message, producing array txwave().
!  
  use crc
  include 'wsprdpsk_params.f90'

  character*22 msg,msgsent
  character*64 cbits
  character*32 sbits
  integer      iuniqueword0
  integer*1,target :: idat(9)
  integer*1 msgbits(68),codeword(ND)
  logical first
  integer ipreamble(16)                      !Freq estimation preamble
  integer isync(32)                          !Long sync vector
  integer imsg(NN),imsgde(NN)                   
  data ipreamble/1,1,1,1,0,0,0,0,0,0,0,0,1,1,1,1/
  data first/.true./
  data iuniqueword0/z'30C9E8AD'/
  save first,isync,ipreamble

  if(first) then
    write(sbits,'(b32.32)') iuniqueword0
    read(sbits,'(32i1)') isync(1:32)
    first=.false.
  endif

  idat=0
  call wqencode(msg,ntype0,idat)             !Source encoding
  id7=idat(7)
  if(id7.lt.0) id7=id7+256
  id7=id7/64
write(*,*) 'idat ',idat
  icrc=crc14(c_loc(idat),9)  
write(*,*) 'icrc: ',icrc
write(*,'(a6,b16.16)') 'icrc: ',icrc
  call wqdecode(idat,msgsent,itype)
  print*,msgsent,itype
  write(cbits,1004) idat(1:6),id7,iand(icrc,z'3FFF')
1004 format(6b8.8,b2.2,b14.14)
  msgbits=0
  read(cbits,1006) msgbits(1:64)
1006 format(64i1)

write(*,'(50i1,1x,14i1,1x,4i1)') msgbits

  call encode204(msgbits,codeword)      !Encode the test message

  imsg(1)=1                         !reference bit
  imsg(2:101)=codeword(1:100)
  imsg(102:132)=isync(1:31)         !only use 31 of the sync bits 
  imsg(133:232)=codeword(101:200)
write(*,'(232i1)') imsg(1:232)
  imsgde(1)=1
  do i=2,232
    imsgde(i)=mod(imsgde(i-1)+imsg(i),2)
  enddo
write(*,*) '-------------'
write(*,'(232i1)') imsgde(1:232)
  return
end subroutine genwsprdpsk
