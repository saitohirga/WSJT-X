subroutine genmsk_short(msg,msgsent,ichk,itone,itype)

  use hashing
  character*22 msg,msgsent
  character*3 crpt,rpt(0:7)
  logical first
  integer itone(35)
  integer ig24(0:4096-1)                  !Codewords for Golay (24,12) code
  integer b11(11)
  data b11/1,1,1,0,0,0,1,0,0,1,0/         !Barker 11 code
  data rpt /'26 ','27 ','28 ','R26','R27','R28','RRR','73 '/
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
  do i=0,7
     if(crpt.eq.rpt(i)) go to 10
  enddo
  go to 900

10 irpt=i                               !Report index, 0-7
  if(ichk.lt.10000) then
     call hash(msg(2:i1-1),i1-2,ihash)  
     ihash=iand(ihash,511)                 !9-bit hash for the two callsigns
     ig=8*ihash + irpt                     !12-bit message information
  else
     ig=ichk-10000
  endif
  ncodeword=ig24(ig)
  itone(1:11)=b11                       !Insert the Barker-11 code
  n=2**24
  do i=12,35                            !Insert codeword into itone array
     n=n/2
     itone(i)=0
     if(iand(ncodeword,n).ne.0) itone(i)=1
  enddo 
  msgsent=msg
  itype=7

  n=count(itone(1:35).eq.0)
  if(mod(n,2).ne.0) stop 'Parity error in genmsk_short.'

900 return
end subroutine genmsk_short

subroutine hash_calls(calls,ih9)

  use hashing
  character*(*) calls
  i1=index(calls,'>')
  call hash(calls(2:i1-1),i1-2,ih9)
  ih9=iand(ih9,511)                      !9-bit hash for the two callsigns

  return
end subroutine hash_calls
