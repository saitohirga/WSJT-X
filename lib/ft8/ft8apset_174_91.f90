subroutine ft8apset_174_91(mycall12,hiscall12,hisgrid6,ncontest,apsym)
  parameter(NAPM=4,KK=91)
  character*37 msg,msgsent
  character*12 mycall12,hiscall12
  character*6 hisgrid6
  character*4 hisgrid
  integer apsym(77)
  integer*1 msgbits(77)
  integer itone(KK)
  
  if(index(hiscall12," ").eq.0) hiscall12="K9ABC"
  msg=trim(mycall12)//' '//trim(hiscall12)//' RRR' 
  i3=1 
  n3=0
!write(*,*) 'apset msg ',msg
  call genft8_174_91(msg,i3,n3,msgsent,msgbits,itone)
  apsym=2*msgbits-1
!write(*,'(29i1,1x,29i1,1x,19i1)') (apsym(1:77)+1)/2
  return
end subroutine ft8apset_174_91
