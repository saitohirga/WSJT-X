subroutine encode174_91(message,codeword)
! Encode an 91-bit message and return a 174-bit codeword. 
! The generator matrix has dimensions (83,91). 
! The code is a (174,91) regular ldpc code with column weight 3.
!

include "ldpc_174_91_a_params.f90"

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
    do j=1,23
      read(g(i)(j:j),"(Z1)") istr
        ibmax=4
        if(j.eq.23) ibmax=3 
        do jj=1, ibmax 
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
end subroutine encode174_91
