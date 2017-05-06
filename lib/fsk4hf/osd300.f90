subroutine osd300(llr,decoded,niterations,cw)
!
! An ordered-statistics decoder for the (300,60) code.
! Based on the ideas in:
! "Soft-decision decoding of linear block codes based on ordered statistics,"
! by Marc P. C. Fossorier and Shu Lin, 
! IEEE Trans Inf Theory, Vol 41, No 5, Sep 1995
! 
character*15 g(240)
integer*1 gen(60,300)
integer*1 genmrb(60,300)
integer*1 temp(60),m0(60),me(60)
integer indices(300)
integer, parameter:: N=300, K=60, M=N-K
integer*1 codeword(N),cw(N),hdec(N)
integer  colorder(N)
integer*1 decoded(K)
integer indx(N)
real llr(N),rx(N),absrx(N)
logical first
data first/.true./
data g/            &
 "316fd3bb18bcefd", &
 "a9c1c984f91244e", &
 "9e04bd3d5d78d89", &
 "f81617089621bd4", &
 "12997ce2f44dbf4", &
 "3ebddaf9b0fa1fc", &
 "d0c114b0b0ef162", &
 "f8c4f115f98bd92", &
 "d0a79c0c5b8ca19", &
 "477f6712f357b3b", &
 "fa28b2444a7e66b", &
 "bedcd4df8d95c64", &
 "da30de73e57022c", &
 "bc099bbb90fe09e", &
 "cffc1e47e5708e8", &
 "713d808563ca9a3", &
 "70fcf1741d5d5d7", &
 "32e80bc15112008", &
 "804cef4df9b18ec", &
 "3736881819d1033", &
 "f4e37db7f9c5efe", &
 "9e84b93d4d78d09", &
 "2250c3518ec830a", &
 "55a529a92e18021", &
 "1cb80b14c9f6eae", &
 "80c504b031ef926", &
 "ece6636d0ac9c6d", &
 "5d50a1690782cd0", &
 "3d54a1fb30937a2", &
 "ba8fe8006318041", &
 "02917ce2fc45bf4", &
 "abc1d984f95a44e", &
 "fc05b4c4ab2d850", &
 "467f7718f357b3b", &
 "472cc094546c6b2", &
 "fcdd94cf8c9cc64", &
 "4dbc1647e970cc8", &
 "6caa465c442aed1", &
 "aead5af8b0da1be", &
 "d8e1fa45a2e8431", &
 "9d4dc4cc63abb7f", &
 "9b2df6b48264637", &
 "7335808563ca3a3", &
 "36bf8d5cd93e6cc", &
 "004ccf4db9b08ec", &
 "90a71c8c598ca19", &
 "f8c5d115f90bc92", &
 "b95546c4e3f7934", &
 "7d50a1690786cd0", &
 "c90939921a0d7c6", &
 "d0c504b030ef126", &
 "ce3e6f9396fc542", &
 "a0072a59f3707f5", &
 "532d0a8fe3da1ea", &
 "68b9e5cd7d142db", &
 "fedc94df8c9dc64", &
 "6da2465c448aed0", &
 "3574aa19cb273c0", &
 "1e54768c6bc6843", &
 "691f65654498186", &
 "fe2c92444a6ef6b", &
 "9caad933e038cc4", &
 "ad4e6f4defb28ec", &
 "4f3d80947c6d2b2", &
 "1caad933e0b8cc4", &
 "b14fd3bf18bcafd", &
 "ad091bbbb0f809e", &
 "90b71c8c598da19", &
 "f8c4d115f90bd92", &
 "9d4dcccc63afb7f", &
 "fa2c92444a6e76b", &
 "1e14768c6bc6c43", &
 "d1baf5aacb86087", &
 "bdf762b92ee51c7", &
 "caacec06ad8a90c", &
 "804ccf4df9b08ec", &
 "69e969f9da5cbd8", &
 "814ccf4df9b086c", &
 "cebe4f9796f4542", &
 "491f65654499186", &
 "8fbf5b9796f6d2a", &
 "ce3e4f9396f4542", &
 "47558560e7debc3", &
 "94aadd33e038cc4", &
 "a94eef4debb286e", &
 "d8e5d115f91bcd2", &
 "532d488fe3da0ab", &
 "664e7bc4e23a80c", &
 "94a2dd33a038cd4", &
 "d8c5d115f91bc92", &
 "0fef071eee60bd5", &
 "9a89a09163c2b97", &
 "0eaf071e6c60bd5", &
 "bc0d1bbbb0fe0be", &
 "f9babd3d12d0f31", &
 "69a969f9da5c9d8", &
 "6e4e7bc4e23a82c", &
 "b0042659f3227f5", &
 "2d51418f0f28347", &
 "be0d5bbbb0da0be", &
 "225003508ec8302", &
 "8fbf4b9796f4d2a", &
 "bead5af9b0da1be", &
 "6ca2465c440aed1", &
 "4fbc1e47ed708c8", &
 "bd091bbbb0fc09e", &
 "b0062259f3307f5", &
 "a8072a59f3727f5", &
 "a0062259f3707f5", &
 "3c380b14c974eae", &
 "30042659f3226f5", &
 "48b9e4cd7d142db", &
 "728bcd4b38308fb", &
 "c0c504b031ef126", &
 "314fd3bb18bcafd", &
 "1c29148305faec1", &
 "44c92a9c28ada63", &
 "88e99b370aae32b", &
 "695081690386ad8", &
 "572d0a8de3da1ea", &
 "467f6610f357b2b", &
 "733d008563da1a3", &
 "d1baf4aacb84087", &
 "4315551d71c8ff0", &
 "48bde4cd7d140db", &
 "3ebd58f9b0da9fc", &
 "51baf4aacb84083", &
 "814e4f4de9b082c", &
 "814ecf4de9b086c", &
 "be0d1bbbb0fa0be", &
 "4f7580947c792b3", &
 "cdf2dce48c39c3b", &
 "d8c5c115f91bc12", &
 "a94e6f4debb28ee", &
 "be2d5afbb0da1be", &
 "cdd6dce48439c2b", &
 "bebd5af9b0da1fe", &
 "fa2892444a6e66b", &
 "51bbf4aacb8c083", &
 "baa73d81eebcd83", &
 "79a2ce47f138cc9", &
 "cc28cf198e6dbd4", &
 "fcde94dfcc9cc64", &
 "1016fcf59286717", &
 "12917ce2fc4dbf4", &
 "4fbc1647e9708c8", &
 "3e382b1cc974fae", &
 "d5bafdaad386087", &
 "0fef473eee60bd5", &
 "c0e504b031ee126", &
 "8bbf5b9797f6d2a", &
 "0eef071e6e60bd5", &
 "1806fcf59386517", &
 "fcdc94df8c9cc64", &
 "141eca2bfa25656", &
 "5fbc1767e9708e8", &
 "5aa4c7803a6bdf1", &
 "b14bd3b718bcafd", &
 "3ebd5af9b0da1fc", &
 "d0a7148c5b8ca09", &
 "a94ecf4debb086e", &
 "733d808563ca1a3", &
 "fd9abd1d92d0f31", &
 "bc091bbbb0fe09e", &
 "d0c514b0b0ef122", &
 "4f7d80947c7d2b3", &
 "8b3f5b97b7f6d2a", &
 "4fbc1767e9708c8", &
 "cebf4f9796f4502", &
 "9c76c880a864e67", &
 "abc1c984f95244e", &
 "795081690786ad8", &
 "467f6710f357b3b", &
 "1c380b14c9f4eae", &
 "d5baf5aac386087", &
 "bedc94df8c95c64", &
 "553d0a8de2da1fa", &
 "0315551d71d8ff0", &
 "1c1eca2ffa25656", &
 "d4bafdaad3c6087", &
 "be2d5bfbb0da0be", &
 "b0062659f3207f5", &
 "5ffc1765e9708e8", &
 "8d62e8bcd303e33", &
 "cc08cf198e69bd4", &
 "573d0a8de3da1fa", &
 "cd56dce48639c2b", &
 "472dc094546c2b2", &
 "7950a16907868d8", &
 "7283cf4b38308fb", &
 "894ecf4de9b086e", &
 "0f7580b47c792b3", &
 "cfbf4b9796f4d0a", &
 "3e380b14c974fae", &
 "732d0085e3da1a3", &
 "1816fcf59386717", &
 "532d088fe3da1ab", &
 "1c300b94c9fcaae", &
 "d0a71c8c5b8ca19", &
 "9e84bd3d5d78d09", &
 "225083508ec830a", &
 "f99abd1d12d0f31", &
 "35f4aa19cb673c0", &
 "cdd2dce48c39c2b", &
 "0f7780b47c792bf", &
 "0e33a5f114f5730", &
 "bc05b4c4ab0d850", &
 "1c300b14c9f4aae", &
 "cfbc1e47ed708e8", &
 "0f7180b47c392b3", &
 "d8c7c115f91be12", &
 "c09148adfa94e97", &
 "9c66c880a844e67", &
 "2226c13b73519f8", &
 "cebf4b9796f4d02", &
 "c0e706b031ee126", &
 "6a6629715e53ce3", &
 "73f9aa824e7d0b8", &
 "473d80947c6c2b2", &
 "1df140e0ddb5632", &
 "473dc0945c6c2b2", &
 "81b4d95f671971d", &
 "663945ca758e2b6", &
 "02ec3d98a2306fd", &
 "5dadb0fa1275690", &
 "4bb8aaa854948d0", &
 "8359ba40886971c", &
 "49cc3d2a2be2ee0", &
 "bfdf13af137f318", &
 "a1de773a2b1ff04", &
 "8ff3945a2f465c7", &
 "532d0087e3da1a3", &
 "f3eaf7fa454d385", &
 "a606aa5aeba07d9", &
 "67f0627b0af8a53", &
 "56698bed69d1c2c", &
 "d5f420011fbf924", &
 "2a8f86c810e2c62", &
 "43cc1cf1208c206", &
 "ee784c4900258de"/

data colorder/    &
0,1,2,3,4,5,6,7,8,9,10,11,123,12,13,14,15,16,17,18, &
19,20,21,22,23,24,25,138,26,145,27,28,29,30,31,32,33,34,35,36, &
37,154,38,39,40,41,42,43,44,144,46,47,48,49,50,51,52,53,143,54, &
125,56,57,58,124,59,120,140,157,160,55,60,61,62,156,162,141,64,65,153, &
181,183,66,170,67,68,69,130,70,164,71,72,73,74,75,63,76,77,135,78, &
79,80,176,169,82,83,84,167,180,85,136,158,129,166,175,142,134,146,121,165, &
88,89,192,90,45,91,92,93,182,189,94,95,96,173,81,97,98,178,122,126, &
132,99,100,152,186,193,101,102,151,103,104,172,159,168,150,190,147,148,201,107, &
205,177,108,198,197,174,127,109,185,110,202,87,199,171,179,187,139,137,106,131, &
206,194,112,149,155,113,128,184,196,86,114,203,212,195,208,105,188,161,163,191, &
200,209,214,204,115,218,133,111,207,117,213,216,211,217,116,215,219,220,210,221, &
118,222,223,225,224,228,226,229,231,227,233,119,234,235,232,230,237,239,236,238, &
240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255,256,257,258,259, &
260,261,262,263,264,265,266,267,268,269,270,271,272,273,274,275,276,277,278,279, &
280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299/

save first,gen

if( first ) then ! fill the generator matrix
  gen=0
  do i=1,240
    do j=1,15
      read(g(i)(j:j),"(Z1)") istr
        do jj=1, 4 
          irow=(j-1)*4+jj
          if( btest(istr,4-jj) ) gen(irow,i)=1
        enddo
    enddo
  enddo
  do irow=1,60
    gen(irow,240+irow)=1
  enddo
first=.false.
endif

! re-order received vector to place systematic msg bits at the end
rx=llr(colorder+1) 

! hard decode the received word
hdec=0            
where(rx .ge. 0) hdec=1

! use magnitude of received symbols as a measure of reliability.
absrx=abs(rx) 
call indexx(absrx,N,indx)  
! re-order the columns of the generator matrix in order of increasing reliability.
do i=1,N
  genmrb(1:K,N+1-i)=gen(1:K,indx(N+1-i))
enddo

! do gaussian elimination to create a generator matrix with the most reliable
! received bits as the systematic bits. if it happens that the K most reliable
! bits are not independent, then we will encounter a zero pivot, in that case
! we dip into the less reliable bits to find K independent MRBs.
! the "indices" array will track any column reordering that is done as part
! of the gaussian elimination.
do i=1,N
  indices(i)=indx(i)
enddo
do id=1,K ! diagonal element indices 
  do ic=id,K+20  ! 
    icol=N-K+ic
    if( icol .gt. N ) icol=241-(icol-300)
    iflag=0
    if( genmrb(id,icol) .eq. 1 ) then
      iflag=1
      if( icol-240 .ne. id ) then ! reorder column
        temp(1:60)=genmrb(1:60,240+id)
        genmrb(1:60,240+id)=genmrb(1:60,icol)
        genmrb(1:60,icol)=temp(1:60) 
        itmp=indices(240+id)
        indices(240+id)=indices(icol)
        indices(icol)=itmp
      endif
      do ii=1,K
        if( ii .ne. id .and. genmrb(ii,N-K+id) .eq. 1 ) then
          genmrb(ii,1:N)=mod(genmrb(ii,1:N)+genmrb(id,1:N),2)
        endif
      enddo
      exit
    endif
  enddo
enddo

! now, use the indices of the K MRB bits to find the hard-decisions
! for those bits. the resulting message is encoded to find the 
! zero'th order codeword estimate (assuming no errors in the MRB).
m0=0
where (rx(indices(241:300)).ge.0.0) m0=1

! the MRB should have only a few errors. Try various error patterns,
! re-encode each errored version of the MRBs, re-order the resulting codeword
! and compare with the original received vector. Keep the best codeword.
nhardmin=300
corrmax=-1.0e32
do i1=0,60
  do i2=i1,60
    do i3=i2,60
      do i4=i3,60
        me=m0
        if( i1 .ne. 0 ) me(i1)=1-me(i1)
        if( i2 .ne. 0 ) me(i2)=1-me(i2)
        if( i3 .ne. 0 ) me(i3)=1-me(i3)
        if( i4 .ne. 0 ) me(i4)=1-me(i4)

! me is the MRB message + error pattern 
! use the modified generator matrix to encode this message, 
! producing a codeword that will be tested against the received vector
        do i=1, 300
          nsum=sum(iand(me,genmrb(1:60,i)))
          codeword(i)=mod(nsum,2)
        enddo
! undo the index permutations to put the "real" message bits at the end
        codeword(indices)=codeword
        nhard=count(codeword .ne. hdec)
!        corr=sum(codeword*rx)  ! to save time use nhard to pick best codeword
        if( nhard .lt. nhardmin ) then
!         if( corr .gt. corrmax ) then
          cw=codeword
          nhardmin=nhard
!          corrmax=corr
          i1min=i1
          i2min=i2
          i3min=i3
          i4min=i4
          if( nhardmin .le. 85 ) goto 200 ! early stopping criterion
        endif
      enddo
    enddo
  enddo 
enddo

200 decoded=cw(241:300)
!write(*,*) absmrb(i1min),absmrb(i2min),absmrb(i3min),absmrb(i4min),nhardmin
niterations=-1
if( nhardmin .le. 90 ) niterations=1
return
end subroutine osd300
