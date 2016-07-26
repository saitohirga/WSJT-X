subroutine genmsk32(msg,msgsent,ichk,itone,itype)

  use hashing
  character*22 msg,msgsent,hashmsg
  character*4 crpt,rpt(0:63)
  logical first
  integer itone(144)
  integer ig32(0:65536-1)                  !Codewords for Golay (24,12) code
  integer*1 codeword(32),bitseq(32)
  integer*1 s8r(8)
  data s8r/1,0,1,1,0,0,0,1/
  data first/.true./
  save first,ig32

  if(first) then
     call ldpc32_table(ig32)             !Define the Golay(24,12) codewords
     do i=0,30
       if( i.lt.5 ) then
         write(rpt(i),'(a1,i2.2,a1)') '-',abs(i-5)
         write(rpt(i+31),'(a2,i2.2,a1)') 'R-',abs(i-5)
       else
         write(rpt(i),'(a1,i2.2,a1)') '+',i-5
         write(rpt(i+31),'(a2,i2.2,a1)') 'R+',i-5
       endif
     enddo
     rpt(62)='RRR '
     rpt(63)='73  '
     first=.false.
  endif

  itype=-1
  msgsent='*** bad message ***'
  itone=0
  i1=index(msg,'>')
  if(i1.lt.9) go to 900
  call fmtmsg(msg,iz)
  crpt=msg(i1+2:i1+5)
  do i=0,63
     if(crpt.eq.rpt(i)) go to 10
  enddo
  go to 900

10 irpt=i                               !Report index, 0-31
  if(ichk.lt.10000) then
     hashmsg=msg(2:i1-1)//' '//crpt
     call hash(hashmsg,22,ihash)          
     ihash=iand(ihash,1023)                 !10-bit hash 
     ig=64*ihash + irpt                     !6-bit report 
  else
     ig=ichk-10000
  endif

  ncodeword=ig32(ig)

  write(*,*) 'codeword is: ',ncodeword,'message is: ',ig,'report index: ',irpt,'hash: ',ihash

  do i=1,32
    codeword(i)=iand(1,ishft(ncodeword,1-i))
  enddo

  bitseq=codeword
  bitseq=2*bitseq-1

! Map I and Q  to tones.
  itone=0
  do i=1, 16
    itone(2*i-1)=(bitseq(2*i)*bitseq(2*i-1)+1)/2;
    itone(2*i)=-(bitseq(2*i)*bitseq(mod(2*i,32)+1)-1)/2;
  enddo

! Flip polarity
  itone=-itone+1 

  msgsent=msg
  itype=7

900 return
end subroutine genmsk32

