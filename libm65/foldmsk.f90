subroutine foldmsk(s2,msglen,nchar,mycall,msg,msg29)

! Fold the 2-d "goodness of fit" array s2 modulo message length, 
! then decode the folded message.

  real s2(0:63,400)
  real fs2(0:63,29)
  integer nfs2(29)
  character mycall*12
  character msg*400,msg29*29
  character cc*64
!                    1         2         3         4         5         6
!          0123456789012345678901234567890123456789012345678901234567890123
  data cc/'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ./?-                 _     @'/

  fs2=0.
  nfs2=0
  do j=1,nchar                           !Fold s2 into fs2, modulo msglen
     jj=mod(j-1,msglen)+1
     nfs2(jj)=nfs2(jj)+1
     do i=0,40
        fs2(i,jj)=fs2(i,jj) + s2(i,j)
     enddo
  enddo

  msg=' '
  do j=1,msglen
     smax=0.
     do k=0,40
        if(fs2(k,j).gt.smax) then
           smax=fs2(k,j)
           kpk=k
        endif
     enddo
     if(kpk.eq.40) kpk=57
     msg(j:j)=cc(kpk+1:kpk+1)
     if(kpk.eq.57) msg(j:j)=' '
  enddo

  msg29=msg(1:msglen)

  call alignmsg('  ',2,msg29,msglen,idone)
  if(idone.eq.0) call alignmsg('CQ',  3,msg29,msglen,idone)
  if(idone.eq.0) call alignmsg('QRZ', 3,msg29,msglen,idone)
  if(idone.eq.0) call alignmsg(mycall,4,msg29,msglen,idone)
  if(idone.eq.0) call alignmsg(' ',   1,msg29,msglen,idone)
  msg29=adjustl(msg29)

  return
end subroutine foldmsk
