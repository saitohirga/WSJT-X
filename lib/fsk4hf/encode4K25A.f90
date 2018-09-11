subroutine encode4K25A(message,codeword)
! A (280,70) rate 1/4 tailbiting convolutional code using
! the "4K25A" polynomials from EbNaut website.
! Code is transparent, has constraint length 25, and has dmin=58
character*10 g1,g2,g3,g4
integer*1 codeword(280)
!integer*1 p1(25),p2(25),p3(25),p4(25)
integer*1 p1(16),p2(16),p3(16),p4(16)
integer*1 gg(100)
integer*1 gen(280,70)
integer*1 itmp(280)
integer*1 message(70)
logical first
data first/.true./
data g1/"106042635"/
data g2/"125445117"/
data g3/"152646773"/
data g4/"167561761"/
!data p1/1,0,0,0,1,1,0,0,0,0,1,0,0,0,1,0,1,1,0,0,1,1,1,0,1/
!data p2/1,0,1,0,1,0,1,1,0,0,1,0,0,1,0,1,0,0,1,0,0,1,1,1,1/
!data p3/1,1,0,1,0,1,0,1,1,0,1,0,0,1,1,0,1,1,1,1,1,1,0,1,1/
!data p4/1,1,1,0,1,1,1,1,0,1,1,1,0,0,0,1,1,1,1,1,1,0,0,0,1/
data p1/1,0,1,0,1,1,0,0,1,1,0,1,1,1,1,1/
data p2/1,0,1,1,0,1,0,0,1,1,1,1,1,0,0,1/
data p3/1,1,0,0,1,0,1,1,0,1,1,1,0,0,1,1/
data p4/1,1,1,0,1,1,0,1,1,1,1,0,0,1,0,1/

save first,gen

if( first ) then ! fill the generator matrix
  gg=0
!  gg(1:25)=p1
!  gg(26:50)=p2
!  gg(51:75)=p3
!  gg(76:100)=p4
  gg(1:16)=p1
  gg(17:32)=p2
  gg(33:48)=p3
  gg(49:64)=p4
  gen=0
!  gen(1:100,1)=gg(1:100)
  gen(1:64,1)=gg(1:64)
  do i=2,70
    gen(:,i)=cshift(gen(:,i-1),-4,1)
  enddo
  first=.false.
endif

codeword=0
do i=1,70
  if(message(i).eq.1) codeword=codeword+gen(:,i)
enddo
codeword=mod(codeword,2)

return
end subroutine encode4K25A
