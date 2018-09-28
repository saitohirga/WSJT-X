subroutine ft8apset_174_91(mycall12,hiscall12,ncontest,apsym)
  parameter(NAPM=4,KK=91)
  character*37 msg,msgsent
  character*12 mycall12,hiscall12,hiscall
  integer apsym(77)
  integer*1 msgbits(77)
  integer itone(KK)
 
  hiscall=hiscall12 
  if(len(trim(hiscall)).eq.0) hiscall="K9ABC"
  if(ncontest.eq.0) then
     msg=trim(mycall12)//' '//trim(hiscall)//' RRR' 
  elseif(ncontest.eq.4) then
     msg=trim(mycall12)//' '//trim(hiscall)//' 599 NJ' 
  endif 
! write(*,*) 'apset msg ',msg
  call genft8_174_91(msg,i3,n3,msgsent,msgbits,itone)
! write(*,*) 'apset msg sent',msgsent
  apsym=2*msgbits-1
! write(*,'(29i1,1x,29i1,1x,19i1)') (apsym(1:77)+1)/2
  return
end subroutine ft8apset_174_91
