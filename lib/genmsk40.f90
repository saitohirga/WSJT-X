subroutine genmsk40(msg,msgsent,ichk,itone,itype)

  use hashing
  character*22 msg,msgsent,hashmsg
  character*32 cwstring
  character*2  cwstrbit
  character*4 crpt,rpt(0:63)
  character*40 pchk_file,gen_file
  logical first
  integer itone(144)
  integer*1 message(16),codeword(32),bitseq(40)
  integer*1 s8r(8)
  data s8r/1,0,1,1,0,0,0,1/
  data first/.true./
  save first,rpt

  if(first) then
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

!####### TEMPORARILY HARDWIRE PCHK AND GEN FILES ################## 
!These files will need to be installed.

  pchk_file="peg-32-16-reg3.pchk"
  gen_file="peg-32-16-reg3.gen"
  call init_ldpc(trim(pchk_file)//char(0),trim(gen_file)//char(0))
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

10 irpt=i                               !Report index, 0-63
  if(ichk.lt.10000) then
     hashmsg=msg(2:i1-1)//' '//crpt
     call hash(hashmsg,22,ihash)          
     ihash=iand(ihash,1023)                 !10-bit hash 
     ig=64*ihash + irpt                     !6-bit report 
  else
     ig=ichk-10000
  endif

  do i=1,16
    message(i)=iand(1,ishft(ig,1-i))
  enddo
  call ldpc_encode(message,codeword)

  cwstring=" "
  do i=1,32
    write(cwstrbit,'(i2)') codeword(i)
    cwstring=cwstring//cwstrbit
  enddo
!  write(*,'(a6,i6,2x,a6,i6,2x,a6,i6)') ' msg: ',ig,'rprt: ',irpt,'hash: ',ihash
!  write(*,'(a6,32i1)') '  cw: ',codeword

  bitseq(1:8)=s8r
  bitseq(9:40)=codeword
  bitseq=2*bitseq-1

! Map I and Q  to tones.
  itone=0
  do i=1, 20
    itone(2*i-1)=(bitseq(2*i)*bitseq(2*i-1)+1)/2;
    itone(2*i)=-(bitseq(2*i)*bitseq(mod(2*i,40)+1)-1)/2;
  enddo

! Flip polarity
  itone=-itone+1 

  msgsent=msg
  itype=7

900 return
end subroutine genmsk40

