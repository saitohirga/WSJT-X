program msksim

use, intrinsic :: iso_c_binding

parameter (N=128, M=46, K=82)
character(1) message(1:K)
character(1) codeword(1:N)
character(1) decoded(1:N)
real lratio(N), bitprobs(N)
character(1) pchk

write(*,*) "calling init_ldpc"
call init_ldpc()

message(1:K)=char(0)
write(*,*) "message: ",message
write(*,*) "calling ldpc_encode"
call ldpc_encode(message,codeword)
write(*,*) "codeword: ",codeword
call ldpc_decode(lratio, decoded, pchk, bitprobs)
write(*,*) decoded

end program msksim
