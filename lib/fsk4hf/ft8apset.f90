subroutine ft8apset(mycall12,hiscall12,hisgrid6,apsym,iaptype)
  parameter(NAPM=4,KK=87)
  character*12 mycall12,hiscall12
  character*22 msg,msgsent
  character*6 mycall,hiscall
  character*6 hisgrid6
  character*4 hisgrid
  integer apsym(KK)
  integer*1 msgbits(KK)
  integer itone(KK)
  
  mycall=mycall12(1:6)
  hiscall=hiscall12(1:6)
  hisgrid=hisgrid6(1:4)
  if(len_trim(hiscall).eq.0) then
    iaptype=1
    hiscall="K9AN"
  else 
    iaptype=2
  endif
  hisgrid=hisgrid6(1:4)
!  if(len_trim(hisgrid).eq.0) hisgrid="EN50"
  if(index(hisgrid," ").eq.0) hisgrid="EN50"
  msg=mycall//' '//hiscall//' '//hisgrid
  call genft8(msg,msgsent,msgbits,itone)
  apsym=2*msgbits-1 
  return
  end subroutine ft8apset 
