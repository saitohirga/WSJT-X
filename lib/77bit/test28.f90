program test28

  parameter (NTOKENS=2063592,MAX22=4194304)
  character*13 call_0,call_1,bare_call_1
  character*1 cerr

  nargs=iargc()
  open(10,file='test28.txt',status='old')

  write(*,1000)
1000 format('Encoded text   Recovered text      n28 Err?   Type'/60('-'))
  
  do iline=1,999999
     if(nargs.eq.0) then
        read(10,'(a13)',end=999) call_0
     else
        call getarg(1,call_0)
     endif
     if(call_0.eq.'             ') exit
     if(call_0(1:3).eq.'CQ ' .and. call_0(4:4).ne.' ') call_0(3:3)='_'
     call_1='             '
     call pack28(call_0,n28)
     call unpack28(n28,call_1)
     cerr=' '
     if(call_0.ne.call_1) cerr='*'
     if(call_1(1:1).eq.'<') then
        i=index(call_1,'>')
        bare_call_1=call_1(2:i-1)//'  '
     endif
     if(call_0.eq.bare_call_1) cerr=' '
     if(call_0(1:3).eq.'CQ_') call_0(3:3)=' '
     if(call_1(1:3).eq.'CQ_') call_1(3:3)=' '
     if(n28.lt.NTOKENS) write(*,1010) call_0,call_1,n28,cerr
1010 format(a13,2x,a13,i10,2x,a1,2x,'Special token')
     if(n28.ge.NTOKENS .and. n28.lt.NTOKENS+MAX22) write(*,1012) call_0,  &
          call_1,n28,cerr
1012 format(a13,2x,a13,i10,2x,a1,2x,'22-bit hash')
     if(n28.ge.NTOKENS+MAX22) write(*,1014) call_0,call_1,n28,cerr
1014 format(a13,2x,a13,i10,2x,a1,2x,'Standard callsign')
     if(nargs.gt.0) exit
  enddo
  
999 end program test28
