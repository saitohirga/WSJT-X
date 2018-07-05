subroutine pack77_4(nwords,w,i3,n3,c77)
! Check Type 3 (One nonstandard call and one hashed call)

  integer*8 n58
  logical ok1,ok2
  character*13 w(19)
  character*77 c77
  character*13 call_1,call_2
  character*11 c11
  character*6 bcall_1,bcall_2
  character*38 c
  data c/' 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ/'/

  if(nwords.eq.2 .or. nwords.eq.3) then
     call_1=w(1)
     if(call_1(1:1).eq.'<') call_1=w(1)(2:len(trim(w(1)))-1)
     call_2=w(2)
     if(call_2(1:1).eq.'<') call_2=w(2)(2:len(trim(w(2)))-1)
     call chkcall(call_1,bcall_1,ok1)
     call chkcall(call_2,bcall_2,ok2)
     if(trim(w(1)).eq.'CQ' .or. (ok1.and.ok2)) then
        if(trim(w(1)).eq.'CQ' .and. len(trim(w(2))).le.4) go to 900
        i3=4
        n3=0
        icq=0
        if(trim(w(1)).eq.'CQ') icq=1
     endif

     if(icq.eq.1) then
        iflip=0
        n12=0
        c11=adjustr(call_2(1:11))
        call save_hash_call(w(2),n10,n12,n22)
     else if(w(1)(1:1).eq.'<') then
        iflip=0
        call save_hash_call(w(1),n10,n12,n22)
        c11=adjustr(call_2(1:11))
     else if(w(2)(1:1).eq.'<') then
        iflip=1
        call save_hash_call(w(2),n10,n12,n22)
        c11=adjustr(call_1(1:11))
     endif
     n58=0
     do i=1,11
        n58=n58*38 + index(c,c11(i:i)) - 1
     enddo
     nrpt=0
     if(trim(w(3)).eq.'RRR') nrpt=1
     if(trim(w(3)).eq.'RR73') nrpt=2
     if(trim(w(3)).eq.'73') nrpt=3
     if(icq.eq.1) then
        iflip=0
        nrpt=0
     endif
     write(c77,1010) n12,n58,iflip,nrpt,icq,i3
1010 format(b12.12,b58.58,b1,b2.2,b1,b3.3)
  endif

900 return
end subroutine pack77_4
