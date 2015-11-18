subroutine geniscat(msg,msgsent,itone)

! Generate an ISCAT waveform.

  parameter (NSZ=1291)
  character msg*28,msgsent*28                    !Message to be transmitted
  integer imsg(30)
  integer itone(NSZ)
  real*8 sps
  character c*42
  integer icos(4)                                !Costas array
  data icos/0,1,3,2/
  data nsync/4/,nlen/2/,ndat/18/
  data c/'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ /.?@-'/

  sps=256.d0*12000.d0/11025.d0
  nsym=int(30*12000.d0/sps)
  nblk=nsync+nlen+ndat

  do i=22,1,-1
     if(msg(i:i).ne.' ' .and. msg(i:i).ne.char(0)) exit
  enddo
  nmsg=i
  msglen=nmsg+1
  k=0
  kk=1
  imsg(1)=40                                  !Always start with BOM char: '@'
  do i=1,nmsg                                 !Define the tone sequence
     imsg(i+1)=36                             !Illegal char set to blank
     do j=1,42
        if(msg(i:i).eq.c(j:j)) imsg(i+1)=j-1
     enddo
  enddo

  do i=1,nsym                                 !Total symbols in 30 s 
     j=mod(i-1,nblk)+1
     if(j.le.nsync) then
        itone(i)=icos(j)                      !Insert 4x4 Costas array
     else if(j.gt.nsync .and. j.le.nsync+nlen) then
        itone(i)=msglen                       !Insert message-length indicator
        if(j.ge.nsync+2) then
           n=msglen + 5*(j-nsync-1)
           if(n.gt.41) n=n-42
           itone(i)=n
        endif
     else
        k=k+1
        kk=mod(k-1,msglen)+1
        itone(i)=imsg(kk)
     endif
  enddo
  msgsent=msg

  return
end subroutine geniscat
