subroutine pack77_01(nwords,w,i3,n3,c77)

! Pack a Type 0.1 message: DXpedition mode
! Example message:  "K1ABC RR73; W9XYZ <KH1/KH7Z> -11"   28 28 10 5

  character*13 w(19),chash(20)
  character*77 c77
  character*6 bcall_1,bcall_2
  logical ok1,ok2
  common/hashcom/ihash10(20),chash

  if(nwords.ne.5) return                !Must have 5 words
  if(trim(w(2)).ne.'RR73;') return      !2nd word must be "RR73;"
  if(w(4)(1:1).ne.'<') return           !4th word must have <...>
  if(index(w(4),'>').lt.1) return
  n=-99
  read(w(5),*,err=1) n
1 if(n.eq.-99) return                   !5th word must be a valid report
  n5=(n+30)/2
  if(n5.lt.0) n5=0
  if(n5.gt.31) n5=31
  call chkcall(w(1),bcall_1,ok1)
  if(.not.ok1) return                   !1st word must be a valid basecall
  call chkcall(w(3),bcall_2,ok2)
  if(.not.ok2) return                   !3rd word must be a valid basecall

! Type 0.1:  K1ABC RR73; W9XYZ <KH1/KH7Z> -11   28 28 10 5       71   DXpedition Mode
  i3=0
  n3=1
  call pack28(w(1),n28a)
  call pack28(w(3),n28b)
  n10=ihashcall(w(4),10)                !Get the 10-bit hash code
  call hash10(n10,w(4),0)               !Save this hash and its callsign
  write(c77,1010) n28a,n28b,n10,n5,n3,i3
1010 format(2b28.28,b10.10,b5.5,2b3.3)
  
  return
end subroutine pack77_01
