program msksim

use, intrinsic :: iso_c_binding

parameter (N=128, M=48, K=80) ! M and N are global variables on the C side.
integer(1) message(1:K)
integer(1) codeword(1:N)
integer(1) decoded(1:K)
real*8 lratio(N)
character(50) pchk_file,gen_file

pchk_file="./jtmode_codes/ldpc-128-80-sf13.pchk"
gen_file="./jtmode_codes/ldpc-128-80-sf13.gen"

call init_ldpc(trim(pchk_file)//char(0),trim(gen_file)//char(0))

message(1:40)=1
message(41:80)=0
call ldpc_encode(message,codeword)

max_iterations=10
ntrials=1000000
rate=real(K)/real(N)

write(*,*) "Eb/N0   ngood    nundetected"
do idb = 0, 11
  db=idb/2.0-0.5
  sigma=1/sqrt( 2*rate*(10**(db/10.0)) )

  ngood=0
  nue=0

  do itrial=1, ntrials

    do i=1,N
      rxdata = 2.0*(codeword(i)-0.5) + sigma*gran()
      lratio(i)=exp(2.0*rxdata/(sigma*sigma))
    enddo

    call ldpc_decode(lratio, decoded, max_iterations, niterations)

    if( niterations .ge. 0 ) then
      nueflag=0
      do i=1,K
        if( message(i) .ne. decoded(i) ) then
          nueflag=1
        endif
      enddo
      if( nueflag .eq. 1 ) then
        nue=nue+1
      else
        ngood=ngood+1;
      endif
    endif

  enddo

  write(*,"(f4.1,1x,i8,1x,i8)") db,ngood,nue

enddo

end program msksim
