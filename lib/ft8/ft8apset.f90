subroutine ft8apset(mycall12,hiscall12,apsym)
  use packjt77
  character*77 c77
  character*37 msg,msgchk
  character*12 mycall12,hiscall12,hiscall
  integer apsym(58)
  logical nohiscall,unpk77_success

  apsym=0
  apsym(1)=99
  apsym(30)=99

  if(len(trim(mycall12)).lt.3) return 

  nohiscall=.false. 
  hiscall=hiscall12 
  if(len(trim(hiscall)).lt.3) then
     hiscall=mycall12  ! use mycall for dummy hiscall - mycall won't be hashed.
     nohiscall=.true.
  endif

! Encode a dummy standard message: i3=1, 28 1 28 1 1 15
!
  msg=trim(mycall12)//' '//trim(hiscall)//' RRR' 
  call pack77(msg,i3,n3,c77)
  call unpack77(c77,1,msgchk,unpk77_success)

  if(i3.ne.1 .or. (msg.ne.msgchk) .or. .not.unpk77_success) return 

  read(c77,'(58i1)',err=1) apsym(1:58)
  apsym=2*apsym-1
  if(nohiscall) apsym(30)=99
  return

1 apsym=0
  apsym(1)=99
  apsym(30)=99
  return
end subroutine ft8apset
