subroutine genmsk_short(msg,msgsent,itone,itype)

  use hashing
  character*22 msg0,msg,msgsent
  character*3 crpt,rpt(0:7)
  integer itone(37)
  integer b11(11)
  integer golay_15_3(0:7)
  data b11/1,1,1,0,0,0,1,0,0,1,0/         !Barker 11 code
  data rpt        /'26 ','27 ','28 ','R26','R27','R28','RRR','73 '/
  data golay_15_3/00000,07025,11704,14025,19164,20909,26468,31765/

  itype=-1
  msgsent='*** bad message ***'
  itone=0
  i1=index(msg,'>')
  if(i1.lt.9) go to 900
  call fmtmsg(msg,iz)
  crpt=msg(i1+2:i1+5)
  do i=0,7
     if(crpt.eq.rpt(i)) go to 10
  enddo
  go to 900

10 itone(1:11)=b11
  irpt=i
  ncodeword=golay_15_3(irpt)            !Save the 15-bit codeword for report
  do i=26,12,-1                         !Insert codeword into itone array
     itone(i)=iand(ncodeword,1)
     ncodeword=ncodeword/2
  enddo 
  call hash(msg(2:i1-1),i1-2,ihash)  
  ihash=iand(ihash,1023)                   !10-bit hash for the two callsigns
  n=ihash
  do i=36,27,-1
     itone(i)=iand(n,1)
     n=n/2
  enddo
  n=count(itone(1:36).eq.0)
  itone(37)=1
  if(iand(n,1).eq.1) itone(37)=0
  msgsent=msg
  itype=7

900 return
end subroutine genmsk_short
