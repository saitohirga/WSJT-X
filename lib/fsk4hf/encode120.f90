subroutine encode120(message,codeword)
! Encode an 60-bit message and return a 120-bit codeword. 
! The generator matrix has dimensions (60,60). 
! The code is a (120,60) regular ldpc code with column weight 3.
! The code was generated using the PEG algorithm.
! After creating the codeword, the columns are re-ordered according to 
! "colorder" to make the codeword compatible with the parity-check matrix 
!
character*15 g(60)
integer*1 codeword(120)
integer colorder(120)
integer*1 gen(60,60)
integer*1 itmp(120)
integer*1 message(60)
integer*1 pchecks(60)
logical first
data first/.true./
data g/            &
 "65541ad98feab6e",&
 "27249940a5895a3",&
 "c80eac7506bf794",&
 "aa50393e3e18d3f",&
 "28527e87d47dced",&
 "5da0dcaf8db048c",&
 "d6509a43ca9b01a",&
 "9a7dadd9c94f1d4",&
 "bb673d3ba07cf29",&
 "65e190f2fbed447",&
 "bc2062a4e520969",&
 "9e357f3feed059b",&
 "aa6b59212036a57",&
 "f78a326722d6565",&
 "416754bc34c6405",&
 "f77000b3f04ff67",&
 "d48fbd7d48c5ab9",&
 "031ffb5db3a70cb",&
 "125964e358c4df5",&
 "bd02c32a5a241ea",&
 "4c15ecdd8561abd",&
 "7f0f1b352c7413e",&
 "26edb94dfd0ae79",&
 "ca1ba1ee0f8fb24",&
 "49878a58cb4544c",&
 "3dbcd0ff821b203",&
 "c1f4440160d5345",&
 "b5ea9dc7a5a70ab",&
 "cebcf7d94976be4",&
 "0968265f5977c88",&
 "c5a36937faa78c3",&
 "f0d4fef11e01c10",&
 "e35fc0c779bebfe",&
 "cf49c3eb41a31d5",&
 "3f0b19352c7013e",&
 "0e15eccd8521abd",&
 "dda8dcaf9d3048c",&
 "fee31438fba59ed",&
 "ad74a27e939189c",&
 "736ac01b439106e",&
 "ab5d2729b29bfa1",&
 "edf11fb02e5a426",&
 "5f38be1c93ecc83",&
 "1e4b3b8dc516b3e",&
 "84443d8bee614c6",&
 "d854d9f355ceac4",&
 "a476b5ece51f0ea",&
 "831c2b36c4c2f68",&
 "f485c97a91615ae",&
 "e9376d828ade9ba",&
 "cac586f089d3185",&
 "b8f8c67613dafe2",&
 "1a3142b401b315d",&
 "87dbedc43265d2e",&
 "bb64ec6e652e7da",&
 "e71bfd4c95dfd38",&
 "31209af07ad4f75",&
 "cff1a8ccc5f4978",&
 "742eded1e1dfefd",&
 "1cd7154a904dac4"/

data colorder/     &
  0,1,2,21,3,4,5,6,7,8,20,10,9,11,12,23,13,28,14,31, &
  15,16,22,26,17,30,18,29,25,32,41,34,19,33,27,36,38,43,42,24, &
  37,39,45,40,35,44,47,46,50,51,53,48,52,56,54,57,55,49,58,61, &
  60,59,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79, &
  80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99, &
  100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119/

save first,gen

if( first ) then ! fill the generator matrix
  gen=0
  do i=1,60
    do j=1,15
      read(g(i)(j:j),"(Z1)") istr
        do jj=1, 4 
          icol=(j-1)*4+jj
          if( btest(istr,4-jj) ) gen(i,icol)=1
        enddo
    enddo
  enddo
first=.false.
endif

do i=1, 60
  nsum=0
  do j=1, 60 
    nsum=nsum+message(j)*gen(i,j)
  enddo
  pchecks(i)=mod(nsum,2)
enddo
itmp(1:60)=pchecks
itmp(61:120)=message(1:60)
codeword(colorder+1)=itmp(1:120)

return
end subroutine encode120
