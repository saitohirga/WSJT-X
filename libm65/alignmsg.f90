subroutine alignmsg(word0,nmin,msg,msglen,idone)

  character*(*) word0
  character*29 msg,word

  word=word0//' '
  idone=0

! Test for two (or more) <space> characters
  if(word(1:2).eq.'  ' .and. len(word).eq.2) then
     i2=index(msg,'  ')
     if((i2.ge.1.and.i2.lt.msglen) .or.                                 &
          (msg(1:1).eq.' '.and.msg(msglen:msglen).eq.' ')) then
        if(i2.eq.1) msg=msg(i2+2:msglen)           !Align on EOM
        if(i2.ge.2) msg=msg(i2+2:msglen)//msg(1:i2-1)
        idone=1
     endif

! Align on single <space> (as last resort)
  else if(word(1:1).eq.' ' .and. len(word).eq.1) then
     i3=index(msg,' ')
     if(i3.ge.1 .and. i3.lt.msglen) msg=msg(i3+1:msglen)//msg(1:i3)
     if(i3.eq.msglen) msg=msg(1:msglen)
     msg=msg(1:msglen)//msg(1:msglen)
     idone=1

! Align on specified word
  else
     call match(word,msg(1:msglen),nstart,nmatch)
     if(nmatch.ge.nmin) then
        if(nstart.eq.1) msg=msg(nstart:msglen)
        if(nstart.gt.1) msg=msg(nstart:msglen)//msg(1:nstart-1)
        idone=1
     endif
  endif

  return
end subroutine alignmsg
