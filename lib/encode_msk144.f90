subroutine encode_msk144(message,codeword)
! Encode an 80-bit message and return a 128-bit codeword. 
! The generator matrix has dimensions (48,80). 
! The code is a (128,80) regular ldpc code with column weight 3.
! The code was generated using the PEG algorithm.
! After creating the codeword, the columns are re-ordered according to 
! "colorder" to make the codeword compatible with the parity-check
! matrix stored in Radford Neal's "pchk" format.
!
character*20 g(48)
integer*1 codeword(128)
integer*1 colorder(128)
integer*1 gen144(48,80)
integer*1 itmp(128)
integer*1 message(80)
integer*1 pchecks(48)
logical first
data first/.true./
data g/                  &  !parity-check generator matrix for (128,80) code
 "24084000800020008000", &
 "b39678f7ccdb1baf5f4c", &
 "10001000400408012000", &
 "08104000100002010800", &
 "dc9c18f61ea0e4b7f05c", &
 "42c040160909ca002c00", &
 "cc50b52b9a80db0d7f9e", &
 "dde5ace80780bae74740", &
 "00800080020000890080", &
 "01020040010400400040", &
 "20008010020000100030", &
 "80400008004000040050", &
 "a4b397810915126f5604", &
 "04040100001040200008", &
 "00800006000888000800", &
 "00010c00000104040001", &
 "cc7cd7d953cdc204eba0", &
 "0094abe7dd146beb16ce", &
 "5af2aec8c7b051c7544a", &
 "14040508801840200088", &
 "7392f5e720f8f5a62c1e", &
 "503cc2a06bff4e684ec9", &
 "5a2efd46f1efbb513b80", &
 "ac06e9513fd411f1de03", &
 "16a31be3dd3082ca2bd6", &
 "28542e0daf62fe1d9332", &
 "00210c002001540c0401", &
 "0ed90d56f84298706a98", &
 "939670f7ecdf9baf4f4c", &
 "cfe41dec47a433e66240", &
 "16d2179c2d5888222630", &
 "408000160108ca002800", &
 "808000830a00018900a0", &
 "9ae2ed8ef3afbf8c3a52", &
 "5aaafd86f3efbfc83b02", &
 "f39658f68cdb0baf1f4c", &
 "9414bb6495106261366a", &
 "71ba18670c08411bf682", &
 "7298f1a7217cf5c62e5e", &
 "86d7a4864396a981369b", &
 "a8042c01ae22fe191362", &
 "9235ae108b2d60d0e306", &
 "dfe5ade807a03be74640", &
 "d2451588e6e27ccd9bc4", &
 "12b51ae39d20e2ea3bde", &
 "a49387810d95136fd604", &
 "467e7578e51d5b3b8a0e", &
 "f6ad1ac7cc3aaa3fe580"/

data colorder/0,1,2,3,4,5,6,7,8,9, &
              10,11,12,13,14,15,24,26,29,30, &
              32,43,44,47,60,77,79,97,101,111, &
              96,38,64,53,93,34,59,94,74,90, &
              108,123,85,57,70,25,69,62,48,49, &
              50,51,52,33,54,55,56,21,58,36, &
              16,61,23,63,20,65,66,67,68,46, &
              22,71,72,73,31,75,76,45,78,17, &
              80,81,82,83,84,42,86,87,88,89, &
              39,91,92,35,37,95,19,27,98,99, &
              100,28,102,103,104,105,106,107,40,109, &
              110,18,112,113,114,115,116,117,118,119, &
              120,121,122,41,124,125,126,127/

save first,gen144

if( first ) then ! fill the generator matrix
  gen144=0
  do i=1,48
    do j=1,5
      read(g(i)( (j-1)*4+1:(j-1)*4+4 ),"(Z4)") istr
        do jj=1,16
          icol=(j-1)*16+jj
          if( btest(istr,16-jj) ) gen144(i,icol)=1
        enddo
    enddo
  enddo
first=.false.
endif

do i=1,48
  nsum=0
  do j=1,80
    nsum=nsum+message(j)*gen144(i,j)
  enddo
  pchecks(i)=mod(nsum,2)
enddo
itmp(1:48)=pchecks
itmp(49:128)=message(1:80)
codeword(colorder+1)=itmp(1:128)

return
end subroutine encode_msk144
