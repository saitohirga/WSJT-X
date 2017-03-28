subroutine encode168(message,codeword)
! Encode an 84-bit message and return a 168-bit codeword. 
! The generator matrix has dimensions (84,84). 
! The code is a (168,84) regular ldpc code with column weight 3.
! The code was generated using the PEG algorithm.
! After creating the codeword, the columns are re-ordered according to 
! "colorder" to make the codeword compatible with the parity-check matrix 
!
character*21 g(84)
integer*1 codeword(168)
integer colorder(168)
integer*1 gen(84,168)
integer*1 itmp(168)
integer*1 message(84)
integer*1 pchecks(84)
logical first
data first/.true./
data g/                  &  !parity generator matrix for (168,84) code
 "25c5bf31ef6710fde9a5a", &
 "18038ef7899cd97a77d96", &
 "270dde504dad076c02b1f", &
 "ed37fe12616565bd7d500", &
 "12b99aa49b5367aff3838", &
 "41cc27f2fac8b228aac21", &
 "2265b233a3cff0b9cee24", &
 "292760cd4f7f4a526a2f1", &
 "2b3db4c8bd831911680cc", &
 "cef2b24ce203bdc60b266", &
 "5045a24f9340915d807ab", &
 "3592b7fc60ba85139502e", &
 "9318023145637bd798f0e", &
 "ad796023c3d58d1e6509c", &
 "3da5eab57f040e75d7413", &
 "27466d1d2734d0ff64830", &
 "2ed50bb1ce313bbfb1ab0", &
 "9a616bda01b25b7e6eeaf", &
 "a84c8c1e9df103169d10d", &
 "a40da29b4aca9234a8942", &
 "dd258d02d79a5f209d3d0", &
 "bdfdc06713511997b5621", &
 "25c58f12f4096cd8ead1a", &
 "b2638a478f21e10fe97de", &
 "4051020f43c605d458156", &
 "f651aad14322a526dae35", &
 "a1c147e31bcc9d87330bf", &
 "7524b53d996d48284647b", &
 "a72e7d25ce31b27282e56", &
 "a97f53b019022350b7519", &
 "56106c6340c0810790984", &
 "c63b8e03a57208635992b", &
 "43a3de2aa3a2b1afb65dc", &
 "9baa64847ead03b77fecc", &
 "251cbd1895c8839c46b0d", &
 "2858107dde2d173e13530", &
 "20096f6a870f636b704e7", &
 "7f833ccbceec52dd6eb79", &
 "a9108dd77b8015b75242a", &
 "689666a79e5579c916236", &
 "aa5dff46459787f69911f", &
 "794558c13138d08171089", &
 "c937042857b291cee8dfd", &
 "6f0bf3248bb9a231366b8", &
 "1c09e756ef1656c96f2d2", &
 "073b875b6774e71fba549", &
 "f7d840aafc037febd2d5c", &
 "dcc0e7d0da5fe17c99ad3", &
 "98238ef7819cd97a77d94", &
 "177c2594743477421a262", &
 "7d01a833c19374fbaaa6e", &
 "7bb800216660482ffd1c4", &
 "39a92e2dba0d4cfda98d2", &
 "44b8d88622698816456a8", &
 "791db2334d6d86639229b", &
 "ba6004b086bd38559ea48", &
 "f94558e13138d18170089", &
 "08ba145302cfbed7845ae", &
 "fb8e64b6da3602168ed38", &
 "1045a2cf1340915d8072b", &
 "7592b6fc64ba85139582e", &
 "3eb238a11bc6654452bae", &
 "b69d8d23b1ea170f70214", &
 "0123dfae84fb20462a614", &
 "4131066ad52a339b3c0d7", &
 "fd2cc26850951c43ed737", &
 "a644d4eb7e56c40f0d050", &
 "0c3bd9d5dab7c9ee2c8fc", &
 "4a198b37af56d7ceffb56", &
 "b6e946c429294cf0eed8b", &
 "98384d75e758774f5ff3b", &
 "5c58e5d9a4d0531d37384", &
 "7a0af02719afed521fd06", &
 "8cd5b2e694e7854abbc70", &
 "1a2f061912d0ea19702d3", &
 "6ffbce557d8fa691a50e8", &
 "d43438e2e2ed5d9f14011", &
 "8d502106083b809adba00", &
 "67e22f9b9983aa715964d", &
 "b31f3a3f3c1f406b1fd58", &
 "529f60ac291f827d97331", &
 "476a815424f2e2cbe641f", &
 "81c82c89bcc3feec42458", &
 "2c882d0e281b178e80364"/

data colorder/0,1,2,3,28,4,5,6,7,8,9,10,11,34,12,32,13,14,15,16,17, &
  18,36,29,42,31,20,21,41,40,30,38,22,19,47,37,46,35,44,33,49,24, &
  43,51,25,26,27,50,52,57,69,54,55,45,59,58,56,61,60,53,48,23,62, &
  63,64,67,66,65,68,39,70,71,72,74,73,75,76,77,80,81,78,82,79,83, &
  84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104, &
  105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125, &
  126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146, &
  147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167/

save first,gen

if( first ) then ! fill the generator matrix
  gen=0
  do i=1,84
    do j=1,21
      read(g(i)(j:j),"(Z1)") istr
        do jj=1, 4 
          icol=(j-1)*4+jj
          if( btest(istr,4-jj) ) gen(i,icol)=1
        enddo
    enddo
  enddo
first=.false.
endif

do i=1, 84 
  nsum=0
  do j=1, 84 
    nsum=nsum+message(j)*gen(i,j)
  enddo
  pchecks(i)=mod(nsum,2)
enddo
itmp(1:84)=pchecks
itmp(85:168)=message(1:84)
codeword(colorder+1)=itmp(1:168)

return
end subroutine encode168
