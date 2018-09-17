subroutine genqra64(msg0,ichk,msgsent,itone,itype)

! Encodes a QRA64 message to yield itone(1:84)

  use packjt
  character*22 msg0
  character*22 message          !Message to be generated
  character*22 msgsent          !Message as it will be received
  integer itone(84)
  character*3 cok               !'   ' or 'OOO'
  logical old_qra_sync
  integer dgen(13)
  integer sent(63)
  integer icos7(0:6)
  data icos7/2,5,6,0,4,1,3/     !Defines a 7x7 Costas array
  save

  if(msg0(1:1).eq.'@') then
     read(msg0(2:5),*,end=1,err=1) nfreq
     go to 2
1    nfreq=1000
2    itone(1)=nfreq
     write(msgsent,1000) nfreq
1000 format(i5,' Hz')
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

     call chkmsg(message,cok,nspecial,flip)
     call packmsg(message,dgen,itype)    !Pack message into 72 bits
     call unpackmsg(dgen,msgsent)        !Unpack to get message sent
     if(ichk.ne.0) go to 999             !Return if checking only
     call qra64_enc(dgen,sent)           !Encode using QRA64

     nsync=10
     inquire(file='old_qra_sync',exist=old_qra_sync)
     if(old_qra_sync) nsync=1

     itone(1:7)=nsync*icos7              !Insert 7x7 Costas array in 3 places
     itone(8:39)=sent(1:32)
     itone(40:46)=nsync*icos7
     itone(47:77)=sent(33:63)
     itone(78:84)=nsync*icos7
  endif

999 return
end subroutine genqra64
