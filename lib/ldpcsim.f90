program ldpcsim

use, intrinsic :: iso_c_binding
use hashing
use packjt

character*22 msg,msgsent,msgreceived
character*80 prefix
character*85 pchk_file,gen_file
character*8 arg
integer*1, allocatable ::  codeword(:), decoded(:), message(:)
real*8, allocatable ::  lratio(:), rxdata(:)
integer ihash

nargs=iargc()
if(nargs.ne.7) then
   print*,'Usage: ldpcsim  <pchk file prefix      >  N   K  niter ndither #trials  s '
   print*,'eg:    ldpcsim  "/pathto/peg-32-16-reg3"  32  16  10     1     1000    0.75'
   return
endif
call getarg(1,prefix)
call getarg(2,arg)
read(arg,*) N 
call getarg(3,arg)
read(arg,*) K 
call getarg(4,arg)
read(arg,*) max_iterations 
call getarg(5,arg)
read(arg,*) max_dither 
call getarg(6,arg)
read(arg,*) ntrials 
call getarg(7,arg)
read(arg,*) s

pchk_file=trim(prefix)//".pchk"
gen_file=trim(prefix)//".gen"

rate=real(K)/real(N)
write(*,*) "rate: ",rate
! don't count hash bits as data bits
!rate=5.0/real(N)

write(*,*) "pchk file: ",pchk_file
write(*,*) "niter= ",max_iterations," ndither= ",max_dither," s= ",s

allocate ( codeword(N), decoded(K), message(K) )
allocate ( lratio(N), rxdata(N) )
call init_ldpc(trim(pchk_file)//char(0),trim(gen_file)//char(0))

msg="K9AN K1JT RRR"
irpt=62
call hash(msg,22,ihash)
ihash=iand(ihash,1023)                 !10-bit hash
ig=64*ihash + irpt                     !6-bit report
write(*,*) irpt,ihash,ig

do i=1,16
  message(i)=iand(1,ishft(ig,1-i))
enddo

call ldpc_encode(message,codeword)
call init_random_seed()

write(*,*) "Eb/N0   ngood  nundetected nbadhash"
do idb = -6, 14
  db=idb/2.0-1.0
  sigma=1/sqrt( 2*rate*(10**(db/10.0)) )
  ngood=0
  nue=0
  nbadhash=0

  do itrial=1, ntrials
call sgran()
! Create a realization of a noisy received word
    do i=1,N
      rxdata(i) = 2.0*(codeword(i)-0.5) + sigma*gran()
!write(*,*) i,gran()
    enddo

! Correct signal normalization is important for this decoder.
    rxav=sum(rxdata)/N
    rx2av=sum(rxdata*rxdata)/N
    rxsig=sqrt(rx2av-rxav*rxav)
    rxdata=rxdata/rxsig
! To match the metric to the channel, s should be set to the noise standard deviation. 
! For now, set s to the value that optimizes decode probability near threshold. 
! The s parameter can be tuned to trade a few tenth's dB of threshold for an order of
! magnitude in UER 
    if( s .le. 0 ) then
      ss=sigma
    else 
      ss=s
    endif

    do i=1,N
      lratio(i)=exp(2.0*rxdata(i)/(ss*ss))
    enddo

! max_iterations is max number of belief propagation iterations
    call ldpc_decode(lratio, decoded, max_iterations, niterations, max_dither, ndither)
! If the decoder finds a valid codeword, niterations will be .ge. 0.
    if( niterations .ge. 0 ) then
      nueflag=0
      nhashflag=0

      imsg=0
      do i=1,16
        imsg=ishft(imsg,1)+iand(1,decoded(17-i))
      enddo
      nrxrpt=iand(imsg,63)
      nrxhash=(imsg-nrxrpt)/64

      if( nrxhash .ne. ihash ) then
        nbadhash=nbadhash+1
        nhashflag=1   
      endif

! Check the message plus hash against what was sent.
      do i=1,K
        if( message(i) .ne. decoded(i) ) then
          nueflag=1
        endif
      enddo

      if( nhashflag .eq. 0 .and. nueflag .eq. 0 ) then
        ngood=ngood+1
      else if( nhashflag .eq. 0 .and. nueflag .eq. 1 ) then
        nue=nue+1;
      endif
    endif
  enddo

  write(*,"(f4.1,1x,i8,1x,i8,1x,i8)") db,ngood,nue,nbadhash

enddo

end program ldpcsim
