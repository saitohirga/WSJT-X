subroutine genmsk32(msg,msgsent,ichk,itone,itype)

  use hashing
  character*22 msg,msgsent,hashmsg
  character*4 crpt,rpt(0:31)
  logical first
  integer itone(144)
  integer ig24(0:4096-1)                  !Codewords for Golay (24,12) code
  integer*1 codeword(24),bitseq(32)
  integer*1 s8r(8)
  data s8r/1,0,1,1,0,0,0,1/
  data rpt /'-04 ','-03 ','-02 ','-01 ','00 ','01 ','02 ','03 ','04 ', &
            '05 ','06 ','07 ','08 ','09 ','10 ', &
            'R-04','R-03','R-02','R-01','R00','R01','R02','R03','R04', &
            'R05','R06','R07','R08','R09','R10', &
            'RRR ','73  '/

  data first/.true./
  save first,ig24

  if(first) then
     call golay24_table(ig24)             !Define the Golay(24,12) codewords
     first=.false.
  endif

  itype=-1
  msgsent='*** bad message ***'
  itone=0
  i1=index(msg,'>')
  if(i1.lt.9) go to 900
  call fmtmsg(msg,iz)
  crpt=msg(i1+2:i1+5)
  do i=0,31
     if(crpt.eq.rpt(i)) go to 10
  enddo
  go to 900

10 irpt=i                               !Report index, 0-31
  if(ichk.lt.10000) then
     hashmsg=msg(2:i1-1)//' '//crpt
     call hash(hashmsg,22,ihash)          
     ihash=iand(ihash,127)                 !7-bit hash 
     ig=32*ihash + irpt                    !12-bit codeword
  else
     ig=ichk-10000
  endif

  ncodeword=ig24(ig)

!write(*,*) 'codeword is: ',ncodeword,'message is: ',ig,'report index: ',irpt,'hash: ',ihash

  do i=1,24
    codeword(i)=iand(1,ishft(ncodeword,1-i))
  enddo

  bitseq(1:8)=s8r
  bitseq(9:32)=codeword 
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

