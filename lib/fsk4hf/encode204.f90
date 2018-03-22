subroutine encode204(message,codeword)
! Encode an 68-bit message and return a 204-bit codeword. 
! The generator matrix has dimensions (136,68). 
! The code is a (204,68) regular ldpc code with column weight 3.
! The code was generated using the PEG algorithm.
! After creating the codeword, the columns are re-ordered according to 
! "colorder" to make the codeword compatible with the parity-check matrix 
!

include "ldpc_204_68_params.f90"

integer*1 codeword(N)
integer*1 gen(M,K)
integer*1 itmp(N)
integer*1 message(K)
integer*1 pchecks(M)
logical first
data first/.true./

save first,gen

if( first ) then ! fill the generator matrix
  gen=0
  do i=1,M
    do j=1,17
      read(g(i)(j:j),"(Z1)") istr
        do jj=1, 4
          icol=(j-1)*4+jj
          if( btest(istr,4-jj) ) gen(i,icol)=1
        enddo
    enddo
  enddo
first=.false.
endif

do i=1,M
  nsum=0
  do j=1,K 
    nsum=nsum+message(j)*gen(i,j)
  enddo
  pchecks(i)=mod(nsum,2)
enddo
itmp(1:M)=pchecks
itmp(M+1:N)=message(1:K)
codeword(colorder+1)=itmp(1:N)

return
end subroutine encode204
