program ldpcsim204

! End-to-end test of the (300,60)/crc10 encoder and decoders.

use crc
use packjt

parameter(NRECENT=10)
character*12 recent_calls(NRECENT)
character*8 arg
integer*1, allocatable ::  codeword(:), decoded(:), message(:)
integer*1, target:: i1Msg8BitBytes(9)
integer*1, target:: i1Dec8BitBytes(9)
integer*1 msgbits(68)
integer*1 apmask(204)
integer*1 cw(204)
integer*2 checksum
integer colorder(204)
integer nerrtot(204),nerrdec(204),nmpcbad(68)
logical checksumok,fsk,bpsk
real*8, allocatable ::  rxdata(:)
real, allocatable :: llr(:)
real dllr(204),llrd(204)

data colorder/                                                              &
         0,  1,  2,  3,  4,  5, 47,  6,  7,  8,  9, 10, 11, 12, 58, 55, 13, &
        14, 15, 46, 17, 18, 60, 19, 20, 21, 22, 23, 24, 25, 57, 26, 27, 49, &
        28, 52, 65, 16, 50, 73, 59, 68, 63, 29, 30, 31, 32, 51, 62, 56, 66, &
        45, 33, 34, 53, 67, 35, 36, 37, 61, 69, 54, 38, 71, 82, 39, 77, 80, &
        83, 78, 84, 48, 41, 85, 40, 64, 75, 96, 74, 72, 76, 86, 87, 89, 90, &
        79, 70, 92, 99, 93,101, 95,100, 97, 94, 42, 98,103,105,102, 43,104, &
        88, 44,106, 81,107,110,108,111,112,109,113,114,117,118,116,121,115, &
       119,122,120,125,129,124,127,126,128, 91,123,133,131,130,134,135,137, &
       136,132,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152, &
       153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169, &
       170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186, &
       187,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203/

do i=1,NRECENT
  recent_calls(i)='            '
enddo
nerrtot=0
nerrdec=0
nmpcbad=0  ! Used to collect the number of errors in the message+crc part of the codeword

nargs=iargc()
if(nargs.ne.4) then
   print*,'Usage: ldpcsim  niter ndeep  #trials  s '
   print*,'eg:    ldpcsim   100    4     1000    0.84'
   print*,'If s is negative, then value is ignored and sigma is calculated from SNR.'
   return
endif
call getarg(1,arg)
read(arg,*) max_iterations 
call getarg(2,arg)
read(arg,*) ndeep
call getarg(3,arg)
read(arg,*) ntrials 
call getarg(4,arg)
read(arg,*) s

fsk=.false.
bpsk=.true.

N=204
K=68
rate=real(K)/real(N)

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

  call encode204(msgbits,codeword)
  call init_random_seed()
  call sgran()

  write(*,*) 'codeword' 
  write(*,'(204i1)') codeword

write(*,*) "Es/N0  SNR2500   ngood  nundetected nbadcrc   sigma"
do idb = 20,-18,-1
!do idb = -16, -16, -1 
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
    if(nerr.ge.1) nerrtot(nerr)=nerrtot(nerr)+1
    nberr=nberr+nerr

! Correct signal normalization is important for this decoder.
    rxav=sum(rxdata)/N
    rx2av=sum(rxdata*rxdata)/N
    rxsig=sqrt(rx2av-rxav*rxav)
    rxdata=rxdata/rxsig
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
    call bpdecode204(llr,apmask,max_iterations,decoded,cw,nharderror,niterations)
    if( (nharderror .lt. 0) .and. (ndeep .ge. 0) ) then
       call osd204(llr, apmask, ndeep, decoded, cw, nhardmin, dmin)
       niterations=nhardmin
    endif
    n2err=0
    do i=1,N
      if( cw(i)*(2*codeword(i)-1.0) .lt. 0 ) n2err=n2err+1
    enddo
!write(*,*) nerr,niterations,n2err
    damp=0.75
    ndither=0
    if( niterations .lt. 0 ) then
      do i=1, ndither
        do in=1,N
          dllr(in)=damp*gran()  
        enddo
        llrd=llr+dllr      
        call bpdecode300(llrd, apmask, max_iterations, decoded, cw, nharderror, niterations)
        if( niterations .ge. 0 ) exit 
      enddo
    endif  

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
      if(nerrmpc.ge.1) nmpcbad(nerrmpc)=nmpcbad(nerrmpc)+1  ! This histogram should inform our selection of CRC poly
      if( ncrcflag .eq. 1 .and. nueflag .eq. 0 ) then
        ngood=ngood+1
        if(nerr.ge.1) nerrdec(nerr)=nerrdec(nerr)+1
      else if( ncrcflag .eq. 1 .and. nueflag .eq. 1 ) then
        nue=nue+1;
      endif
    endif
  enddo
  snr2500=db+10*log10(200.0/116.0/2500.0)
  pberr=real(nberr)/(real(ntrials*N))
  write(*,"(f4.1,4x,f5.1,1x,i8,1x,i8,1x,i8,8x,f5.2,8x,e10.3)") db,snr2500,ngood,nue,nbadcrc,ss,pberr

enddo

open(unit=23,file='nerrhisto.dat',status='unknown')
do i=1,120
  write(23,'(i4,2x,i10,i10,f10.2)') i,nerrdec(i),nerrtot(i),real(nerrdec(i))/real(nerrtot(i)+1e-10)
enddo
close(23)
open(unit=25,file='nmpcbad.dat',status='unknown')
do i=1,68
  write(25,'(i4,2x,i10)') i,nmpcbad(i)
enddo
close(25)



end program ldpcsim204
