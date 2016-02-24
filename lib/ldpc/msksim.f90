program msksim

use, intrinsic :: iso_c_binding

parameter (N=128, M=46, K=82) ! M and N are global variables on the C side. 
integer(1) message(1:K)
integer(1) codeword(1:N)
integer(1) decoded(1:N)
integer(1) pchk(1:M)
real*8 lratio(N), bitprobs(N)

write(*,*) "calling init_ldpc"
call init_ldpc()

message(1:K)=0
message(10)=1
write(*,*) "calling ldpc_encode"
call ldpc_encode(message,codeword)
write(*,*) "calling ldpc_decode"
do i=1,N
lratio(i)=exp(2.0*(codeword(i)-0.5))
enddo
lratio(10)=10.0
bitprobs(1:N)=0.0 ! shouldn't need this
call ldpc_decode(lratio, decoded, pchk, bitprobs)
do i=1,N
write(*,*) i,bitprobs(i), lratio(i)
enddo
end program msksim
