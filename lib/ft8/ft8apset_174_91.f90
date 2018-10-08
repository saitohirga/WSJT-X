subroutine ft8apset_174_91(mycall12,hiscall12,apsym)
  use packjt77
  character*77 c77
  character*37 msg
  character*12 mycall12,hiscall12,hiscall
  integer apsym(58)
  integer*1 msgbits(77)
  logical nohiscall

  if(len(trim(mycall12)).eq.0) then
     apsym=0
     apsym(1)=99
     apsym(30)=99
     return
  endif

  nohiscall=.false. 
  hiscall=hiscall12 
  if(len(trim(hiscall)).eq.0) then
     hiscall="K9ABC"
     nohiscall=.true.
  endif

! Encode a dummy standard message: i3=1, 28 1 28 1 1 15
!
  msg=trim(mycall12)//' '//trim(hiscall)//' RRR' 
  call pack77(msg,i3,n3,c77)
  if(i3.ne.1) then
    apsym=0
    apsym(1)=99
    apsym(30)=99
    return
  endif

  read(c77,'(58i1)',err=1) apsym(1:58)
  if(nohiscall) apsym(30)=99
  return

1 apsym=0
  apsym(1)=99
  apsym(30)=99
  return
end subroutine ft8apset_174_91
