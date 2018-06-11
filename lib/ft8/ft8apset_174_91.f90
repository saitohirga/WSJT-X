subroutine ft8apset_174_91(mycall12,mygrid6,hiscall12,hisgrid6,bcontest,apsym)
  parameter(NAPM=4,KK=91)
  character*12 mycall12,hiscall12
  character*22 msg,msgsent
  character*6 mycall,hiscall
  character*6 mygrid6,hisgrid6
  character*4 hisgrid
  logical bcontest
  integer apsym(KK)
  integer*1 msgbits(KK)
  integer itone(KK)
  
  mycall=mycall12(1:6)
  hiscall=hiscall12(1:6)
  if(index(hiscall," ").eq.0) hiscall="K9ABC"
  hisgrid=hisgrid6(1:4)
  if(index(hisgrid," ").eq.0) hisgrid="AA00"
  msg=mycall//' '//hiscall//' '//hisgrid
  i5bit=0                                       ! ### TEMPORARY ??? ###
  call genft8_174_91(msg,mygrid6,bcontest,i5bit,msgsent,msgbits,itone)
  apsym=2*msgbits-1
  return
end subroutine ft8apset_174_91
