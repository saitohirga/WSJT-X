program ldpcsim120
! End to end test of the (120,60)/crc10 encoder and decoder.
use crc
use packjt

parameter(NRECENT=10)
character*12 recent_calls(NRECENT)
character*22 msg,msgsent,msgreceived
character*8 arg
integer*1, allocatable ::  codeword(:), decoded(:), message(:)
integer*1, target:: i1Msg8BitBytes(9)
integer*1, target:: i1Dec8BitBytes(9)
integer*1 msgbits(60)
integer*1 apmask(120)
integer*2 checksum
integer colorder(120)
integer nerrtot(120),nerrdec(120),nmpcbad(60)
logical checksumok,fsk,bpsk
real*8, allocatable ::  rxdata(:)
real, allocatable :: llr(:)

data colorder/   &
  0,1,2,21,3,4,5,6,7,8,20,10,9,11,12,23,13,28,14,31, &
  15,16,22,26,17,30,18,29,25,32,41,34,19,33,27,36,38,43,42,24, &
  37,39,45,40,35,44,47,46,50,51,53,48,52,56,54,57,55,49,58,61, &
  60,59,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79, &
  80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99, &
  100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119/

do i=1,NRECENT
  recent_calls(i)='            '
enddo
nerrtot=0
nerrdec=0
nmpcbad=0  ! Used to collect the number of errors in the message+crc part of the codeword

nargs=iargc()
if(nargs.ne.3) then
   print*,'Usage: ldpcsim  niter  #trials  s '
   print*,'eg:    ldpcsim    10   1000    0.84'
   print*,'If s is negative, then value is ignored and sigma is calculated from SNR.'
   return
endif
call getarg(1,arg)
read(arg,*) max_iterations 
call getarg(2,arg)
read(arg,*) ntrials 
call getarg(3,arg)
read(arg,*) s

fsk=.false.
bpsk=.true.

! don't count crc bits as data bits
N=120
K=60
! scale Eb/No for a (120,50) code
rate=real(50)/real(N)

write(*,*) "rate: ",rate
write(*,*) "niter= ",max_iterations," s= ",s

allocate ( codeword(N), decoded(K), message(K) )
allocate ( rxdata(N), llr(N) )

! The message should be packed into the first 7 bytes
  i1Msg8BitBytes(1:6)=85
  i1Msg8BitBytes(7)=64
! The CRC will be put into the last 2 bytes
  i1Msg8BitBytes(8:9)=0
  checksum = crc10 (c_loc (i1Msg8BitBytes), 9)
! For reference, the next 3 lines show how to check the CRC
  i1Msg8BitBytes(8)=checksum/256
  i1Msg8BitBytes(9)=iand (checksum,255)
  checksumok = crc10_check(c_loc (i1Msg8BitBytes), 9)
  if( checksumok ) write(*,*) 'Good checksum'
write(*,*) i1Msg8BitBytes(1:9)

  mbit=0
  do i=1, 7 
    i1=i1Msg8BitBytes(i)
    do ibit=1,8
      mbit=mbit+1
      msgbits(mbit)=iand(1,ishft(i1,ibit-8))
    enddo
  enddo
  i1=i1Msg8BitBytes(8) ! First 2 bits of crc10 are LSB of this byte
  do ibit=1,2
    msgbits(50+ibit)=iand(1,ishft(i1,ibit-2))
  enddo
  i1=i1Msg8BitBytes(9) ! Now shift in last 8 bits of the CRC
  do ibit=1,8
    msgbits(52+ibit)=iand(1,ishft(i1,ibit-8))
  enddo

  write(*,*) 'message'
  write(*,'(9(8i1,1x))') msgbits

  call encode120(msgbits,codeword)
  call init_random_seed()
  call sgran()

  write(*,*) 'codeword' 
  write(*,'(15(8i1,1x))') codeword

write(*,*) "Es/N0  SNR2500   ngood  nundetected nbadcrc   sigma"
do idb = -10, 24 
  db=idb/2.0-1.0
!  sigma=1/sqrt( 2*rate*(10**(db/10.0)) )  ! to make db represent Eb/No
  sigma=1/sqrt( 2*(10**(db/10.0)) )        ! db represents Es/No
  ngood=0
  nue=0
  nbadcrc=0
  nberr=0
  do itrial=1, ntrials
! Create a realization of a noisy received word
    do i=1,N
      if( bpsk ) then
        rxdata(i) = 2.0*codeword(i)-1.0 + sigma*gran()
      elseif( fsk ) then
        if( codeword(i) .eq. 1 ) then
          r1=(1.0 + sigma*gran())**2 + (sigma*gran())**2
          r2=(sigma*gran())**2 + (sigma*gran())**2
        elseif( codeword(i) .eq. 0 ) then
          r2=(1.0 + sigma*gran())**2 + (sigma*gran())**2
          r1=(sigma*gran())**2 + (sigma*gran())**2
        endif 
        rxdata(i)=0.35*(sqrt(r1)-sqrt(r2))
!        rxdata(i)=0.35*(exp(r1)-exp(r2))
!        rxdata(i)=0.12*(log(r1)-log(r2))
      endif
    enddo
    nerr=0
    do i=1,N
      if( rxdata(i)*(2*codeword(i)-1.0) .lt. 0 ) nerr=nerr+1
    enddo
    nerrtot(nerr)=nerrtot(nerr)+1
    nberr=nberr+nerr

! Correct signal normalization is important for this decoder.
!    rxav=sum(rxdata)/N
!    rx2av=sum(rxdata*rxdata)/N
!    rxsig=sqrt(rx2av-rxav*rxav)
!    rxdata=rxdata/rxsig
! To match the metric to the channel, s should be set to the noise standard deviation. 
! For now, set s to the value that optimizes decode probability near threshold. 
! The s parameter can be tuned to trade a few tenth's dB of threshold for an order of
! magnitude in UER 
    if( s .lt. 0 ) then
      ss=sigma
    else 
      ss=s
    endif

    llr=2.0*rxdata/(ss*ss)
    apmask=0

! max_iterations is max number of belief propagation iterations
    call bpdecode120(llr, apmask, max_iterations, decoded, niterations)


! If the decoder finds a valid codeword, niterations will be .ge. 0.
    if( niterations .ge. 0 ) then
! Check the CRC
      do ibyte=1,6
        itmp=0
        do ibit=1,8
          itmp=ishft(itmp,1)+iand(1,decoded((ibyte-1)*8+ibit))
        enddo
        i1Dec8BitBytes(ibyte)=itmp
      enddo
      i1Dec8BitBytes(7)=decoded(49)*128+decoded(50)*64
! Need to pack the received crc into bytes 8 and 9 for crc10_check
      i1Dec8BitBytes(8)=decoded(51)*2+decoded(52)
      i1Dec8BitBytes(9)=decoded(53)*128+decoded(54)*64+decoded(55)*32+decoded(56)*16
      i1Dec8BitBytes(9)=i1Dec8BitBytes(9)+decoded(57)*8+decoded(58)*4+decoded(59)*2+decoded(60)*1
      ncrcflag=0
      if( crc10_check( c_loc( i1Dec8BitBytes ), 9 ) ) ncrcflag=1

      if( ncrcflag .ne. 1 ) then
        nbadcrc=nbadcrc+1
      endif
      nueflag=0

      nerrmpc=0
      do i=1,K   ! find number of errors in message+crc part of codeword
        if( msgbits(i) .ne. decoded(i) ) then
          nueflag=1
          nerrmpc=nerrmpc+1 
        endif
      enddo
      nmpcbad(nerrmpc)=nmpcbad(nerrmpc)+1  ! This histogram should inform our selection of CRC poly
      if( ncrcflag .eq. 1 .and. nueflag .eq. 0 ) then
        ngood=ngood+1
        nerrdec(nerr)=nerrdec(nerr)+1
      else if( ncrcflag .eq. 1 .and. nueflag .eq. 1 ) then
        nue=nue+1;
      endif
    endif
  enddo
  snr2500=db+10*log10(0.4166/2500.0)
  pberr=real(nberr)/(real(ntrials*N))
  write(*,"(f4.1,4x,f5.1,1x,i8,1x,i8,1x,i8,8x,f5.2,8x,e10.3)") db,snr2500,ngood,nue,nbadcrc,ss,pberr

enddo

open(unit=23,file='nerrhisto.dat',status='unknown')
do i=1,120
  write(23,'(i4,2x,i10,i10,f10.2)') i,nerrdec(i),nerrtot(i),real(nerrdec(i))/real(nerrtot(i)+1e-10)
enddo
close(23)
open(unit=25,file='nmpcbad.dat',status='unknown')
do i=1,60
  write(25,'(i4,2x,i10)') i,nmpcbad(i)
enddo
close(25)



end program ldpcsim120
