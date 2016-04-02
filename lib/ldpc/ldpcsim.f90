program msksim

use, intrinsic :: iso_c_binding

! To change to a new code, edit the following line and the filenames
! that contain the parity check and generator matrices.
parameter (N=198, M=126, K=72) ! M and N are global variables on the C side.

character(50) pchk_file,gen_file
integer(1) codeword(1:N), decoded(1:K), message(1:K)
real*8 lratio(N), rxdata(N)

pchk_file="./jtmode_codes/peg-198-72-reg4.pchk"
gen_file="./jtmode_codes/peg-198-72-reg4.gen"

rate=real(K)/real(N)

call init_ldpc(trim(pchk_file)//char(0),trim(gen_file)//char(0))

message(1:K/2)=1
message((K/2+1):K)=0
call ldpc_encode(message,codeword)

max_iterations=50
ntrials=1000000

write(*,*) "Eb/N0   ngood    nundetected"
do idb = 0, 11
  db=idb/2.0-0.5
  sigma=1/sqrt( 2*rate*(10**(db/10.0)) )

  ngood=0
  nue=0

  do itrial=1, ntrials

    do i=1,N
      rxdata(i) = 2.0*(codeword(i)-0.5) + sigma*gran()
    enddo

! correct signal normalization is important for this decoder.
    rxav=sum(rxdata)/N
    rx2av=sum(rxdata*rxdata)/N
    rxsig=sqrt(rx2av-rxav*rxav)
    rxdata=rxdata/rxsig

! s can be tuned to trade a few tenth's dB of threshold 
! for an order of magnitude in UER 
    do i=1,N
      s=0.75
      lratio(i)=exp(2.0*rxdata(i)/(s*s))
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
