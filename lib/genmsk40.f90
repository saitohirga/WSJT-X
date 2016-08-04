subroutine genmsk40(msg,msgsent,ichk,itone,itype,pchk_file,fname1,fname2,encodeExeFile)

  use hashing
  character*22 msg,msgsent,hashmsg
  character*32 cwstring
  character*2  cwstrbit
  character*4 crpt,rpt(0:15)
  character*512 encodeExeFile
  character*512 pchk_file,gen_file
  character*512 pchk_file40,gen_file40
  character*120 fname1,fname2
  character*2048 cmnd
  logical first
  integer itone(144)
  integer*1 message(16),codeword(32),bitseq(40)
  integer*1 s8r(8)
  data s8r/1,0,1,1,0,0,0,1/
  data first/.true./
  data rpt/"-03 ","+00 ","+03 ","+06 ","+10 ","+13 ","+16 ", &
           "R-03","R+00","R+03","R+06","R+10","R+13","R+16", &
           "RRR ","73  "/
  save first,rpt

! Temporarily hardwire filenames and init on every call
  i=index(pchk_file,"128-80")
  pchk_file40=pchk_file(1:i-1)//"32-16"//pchk_file(i+6:)
  i=index(pchk_file40,".pchk")
  gen_file40=pchk_file40(1:i-1)//".gen"
!  call init_ldpc(trim(pchk_file40)//char(0),trim(gen_file40)//char(0))
  itype=-1
  msgsent='*** bad message ***'
  itone=0
  i1=index(msg,'>')
  if(i1.lt.9) go to 900
  call fmtmsg(msg,iz)
  crpt=msg(i1+2:i1+5)
  do i=0,15
     if(crpt.eq.rpt(i)) go to 10
  enddo
  go to 900

10 irpt=i                               !Report index, 0-63
  if(ichk.lt.10000) then
     hashmsg=msg(2:i1-1)//' '//crpt
     call hash(hashmsg,22,ihash)          
     ihash=iand(ihash,4095)                 !10-bit hash 
     ig=16*ihash + irpt                     !6-bit report 
  else
     ig=ichk-10000
  endif

  do i=1,16
    message(i)=iand(1,ishft(ig,1-i))
  enddo

!  call ldpc_encode(message,codeword)
  open(24,file=fname1,status='unknown')
  write(24,1010) message
1010 format(16i1)
  close(24)
  cmnd=trim(encodeExeFile)//' "'//trim(pchk_file40)//'" "'//trim(gen_file40)//'" "'        &
       //trim(fname1)//'" "'//trim(fname2)//'"'
  call system(cmnd)
  open(24,file=fname2,status='old')
  read(24,1020) codeword
1020 format(32i1)
  close(24)

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

