subroutine ft8apset(mycall12,hiscall12,apsym)
  parameter(NAPM=4,KK=87)
  character*12 mycall12,hiscall12
  character*37 msg,msgsent
  character*6 mycall,hiscall
  character*6 hisgrid6
  character*4 hisgrid
  integer apsym(75)
  integer*1 msgbits(77)
  integer itone(79)
  
  mycall=mycall12(1:6)
  hiscall=hiscall12(1:6)
  if(len(trim(hiscall)).eq.0) hiscall="K9ABC"
  msg=mycall//' '//hiscall//' RRR' 
  i3=0 
  n3=0
  isync=1
  call genft8(msg,i3,n3,isync,msgsent,msgbits,itone)
  apsym=2*msgbits(1:75)-1
  return
end subroutine ft8apset
