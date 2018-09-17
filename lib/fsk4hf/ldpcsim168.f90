program ldpcsim168
! End to end test of the (168,84)/crc12 encoder and decoder.
use crc
use packjt

parameter(NRECENT=10)
character*12 recent_calls(NRECENT)
character*22 msg,msgsent,msgreceived
character*8 arg
integer*1, allocatable ::  codeword(:), decoded(:), message(:)
integer*1, target:: i1Msg8BitBytes(11)
integer*1 msgbits(84)
integer*1 apmask(168), cw(168)
integer*2 checksum
integer*4 i4Msg6BitWords(13)
integer colorder(168)
integer nerrtot(168),nerrdec(168),nmpcbad(84)
logical checksumok,fsk,bpsk
real*8, allocatable ::  rxdata(:)
real, allocatable :: llr(:)

data colorder/0,1,2,3,28,4,5,6,7,8,9,10,11,34,12,32,13,14,15,16,17, &
  18,36,29,42,31,20,21,41,40,30,38,22,19,47,37,46,35,44,33,49,24, &
  43,51,25,26,27,50,52,57,69,54,55,45,59,58,56,61,60,53,48,23,62, &
  63,64,67,66,65,68,39,70,71,72,74,73,75,76,77,80,81,78,82,79,83, &
  84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104, &
  105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125, &
  126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146, &
  147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167/

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
N=168
K=84
! scale Eb/No for a (168,72) code
rate=real(72)/real(N)

write(*,*) "rate: ",rate
write(*,*) "niter= ",max_iterations," s= ",s

allocate ( codeword(N), decoded(K), message(K) )
allocate ( rxdata(N), llr(N) )

!  msg="K1JT K9AN EN50"
  msg="G4WJS K9AN EN50"
  call packmsg(msg,i4Msg6BitWords,itype) !Pack into 12 6-bit bytes
  call unpackmsg(i4Msg6BitWords,msgsent) !Unpack to get msgsent
  write(*,*) "message sent ",msgsent

  i4=0
  ik=0
  im=0
  do i=1,12
    nn=i4Msg6BitWords(i)
    do j=1, 6
      ik=ik+1
      i4=i4+i4+iand(1,ishft(nn,j-6))
      i4=iand(i4,255)
      if(ik.eq.8) then
        im=im+1
!           if(i4.gt.127) i4=i4-256
        i1Msg8BitBytes(im)=i4
        ik=0
      endif
    enddo
  enddo

  i1Msg8BitBytes(10:11)=0
  checksum = crc12 (c_loc (i1Msg8BitBytes), 11)
! For reference, the next 3 lines show how to check the CRC
  i1Msg8BitBytes(10)=checksum/256
  i1Msg8BitBytes(11)=iand (checksum,255)
  checksumok = crc12_check(c_loc (i1Msg8BitBytes), 11)
  if( checksumok ) write(*,*) 'Good checksum'

  mbit=0
  do i=1, 9 
    i1=i1Msg8BitBytes(i)
    do ibit=1,8
      mbit=mbit+1
      msgbits(mbit)=iand(1,ishft(i1,ibit-8))
    enddo
  enddo
  i1=i1Msg8BitBytes(10) ! First 4 bits of crc12 are LSB of this byte
  do ibit=1,4
    msgbits(72+ibit)=iand(1,ishft(i1,ibit-4))
  enddo
  i1=i1Msg8BitBytes(11) ! Now shift in last 8 bits of the CRC
  do ibit=1,8
    msgbits(76+ibit)=iand(1,ishft(i1,ibit-8))
  enddo

  write(*,*) 'message'
  write(*,'(11(8i1,1x))') msgbits

  call encode168(msgbits,codeword)
  call init_random_seed()
  call sgran()

  write(*,*) 'codeword' 
  write(*,'(21(8i1,1x))') codeword

write(*,*) "Es/N0  SNR2500   ngood  nundetected nbadcrc   sigma"
do idb = 6,-6,-1 
  db=idb/2.0-1.0
  sigma=1/sqrt( 2*(10**(db/10.0)) )
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
    nap=0 ! number of AP bits
    llr(colorder(168-84+1:168-84+nap)+1)=5*(2.0*msgbits(1:nap)-1.0)
    apmask=0
    apmask(colorder(168-84+1:168-84+nap)+1)=1

! max_iterations is max number of belief propagation iterations
    call bpdecode168(llr, apmask, max_iterations, decoded, niterations)
!    if( niterations .eq. -1 ) then
!      norder=3
!      call osd168(llr, norder, decoded, niterations, cw)
!    endif
! If the decoder finds a valid codeword, niterations will be .ge. 0.
    if( niterations .ge. 0 ) then
      call extractmessage168(decoded,msgreceived,ncrcflag,recent_calls,nrecent)
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

write(37,*) niterations, ncrcflag, nueflag
      nmpcbad(nerrmpc)=nmpcbad(nerrmpc)+1
      if( ncrcflag .eq. 1 ) then
        if( nueflag .eq. 0 ) then
          ngood=ngood+1
          nerrdec(nerr)=nerrdec(nerr)+1
        else if( nueflag .eq. 1 ) then
          nue=nue+1;
        endif
      endif
    endif
  enddo
  snr2500=db+10*log10(10.417/2500.0)
  pberr=real(nberr)/(real(ntrials*N))
  write(*,"(f4.1,4x,f5.1,1x,i8,1x,i8,1x,i8,8x,f5.2,8x,e10.3)") db,snr2500,ngood,nue,nbadcrc,ss,pberr

enddo

open(unit=23,file='nerrhisto.dat',status='unknown')
do i=1,168
  write(23,'(i4,2x,i10,i10,f10.2)') i,nerrdec(i),nerrtot(i),real(nerrdec(i))/real(nerrtot(i)+1e-10)
enddo
close(23)
open(unit=25,file='nmpcbad.dat',status='unknown')
do i=1,84
  write(25,'(i4,2x,i10)') i,nmpcbad(i)
enddo
close(25)



end program ldpcsim168
