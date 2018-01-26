program ldpcsim

use, intrinsic :: iso_c_binding
use iso_c_binding, only: c_loc,c_size_t
use hashing
use packjt
parameter(NRECENT=10)
character*12 recent_calls(NRECENT)
character*22 msg,msgsent,msgreceived
character*8 arg
integer*1, allocatable ::  codeword(:), decoded(:), message(:)
integer*1, target:: i1Msg8BitBytes(10)
integer*1 i1hash(4)
integer*1 msgbits(80)
integer*4 i4Msg6BitWords(13)
integer ihash
integer nerrtot(128),nerrdec(128)
real*8, allocatable ::  lratio(:), rxdata(:), rxavgd(:)
real, allocatable :: yy(:), llr(:)
equivalence(ihash,i1hash)

do i=1,NRECENT
  recent_calls(i)='            '
enddo
nerrtot=0
nerrdec=0

nargs=iargc()
if(nargs.ne.4) then
   print*,'Usage: ldpcsim  niter   navg  #trials  s '
   print*,'eg:    ldpcsim    10     1     1000    0.75'
   return
endif
call getarg(1,arg)
read(arg,*) max_iterations 
call getarg(2,arg)
read(arg,*) navg 
call getarg(3,arg)
read(arg,*) ntrials 
call getarg(4,arg)
read(arg,*) s

! don't count hash bits as data bits
N=128
K=72
rate=real(K)/real(N)

write(*,*) "rate: ",rate

write(*,*) "niter= ",max_iterations," navg= ",navg," s= ",s

allocate ( codeword(N), decoded(K), message(K) )
allocate ( lratio(N), rxdata(N), rxavgd(N), yy(N), llr(N) )

msg="K9AN K1JT EN50"
  call packmsg(msg,i4Msg6BitWords,itype,.false.) !Pack into 12 6-bit bytes
  call unpackmsg(i4Msg6BitWords,msgsent,.false.,'      ') !Unpack to get msgsent
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
 
  ihash=nhash(c_loc(i1Msg8BitBytes),int(9,c_size_t),146)
  ihash=2*iand(ihash,32767)                   !Generate the 8-bit hash
  i1Msg8BitBytes(10)=i1hash(1)                !Hash code to byte 10
  mbit=0
  do i=1, 10
    i1=i1Msg8BitBytes(i)
    do ibit=1,8
      mbit=mbit+1
      msgbits(mbit)=iand(1,ishft(i1,ibit-8))
    enddo
  enddo
  call encode_msk144(msgbits,codeword)
  call init_random_seed()

write(*,*) "Eb/N0  SNR2500   ngood  nundetected nbadhash  sigma"
do idb = -6, 14
  db=idb/2.0-1.0
  sigma=1/sqrt( 2*rate*(10**(db/10.0)) )
  ngood=0
  nue=0
  nbadhash=0

  do itrial=1, ntrials
    rxavgd=0d0
    do iav=1,navg
      call sgran()
! Create a realization of a noisy received word
      do i=1,N
        rxdata(i) = 2.0*codeword(i)-1.0 + sigma*gran()
      enddo
      rxavgd=rxavgd+rxdata
    enddo
    rxdata=rxavgd
    nerr=0
    do i=1,N
      if( rxdata(i)*(2*codeword(i)-1.0) .lt. 0 ) nerr=nerr+1
    enddo
    nerrtot(nerr)=nerrtot(nerr)+1

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
    lratio=exp(llr)
    yy=rxdata

! max_iterations is max number of belief propagation iterations
!    call ldpc_decode(lratio, decoded, max_iterations, niterations, max_dither, ndither)
!    call amsdecode(yy, max_iterations, decoded, niterations)
!    call bitflipmsk144(rxdata, decoded, niterations)
    call bpdecode144(llr, max_iterations, decoded, niterations)

! If the decoder finds a valid codeword, niterations will be .ge. 0.
    if( niterations .ge. 0 ) then
      call extractmessage144(decoded,msgreceived,nhashflag,recent_calls,nrecent)
      if( nhashflag .ne. 1 ) then
        nbadhash=nbadhash+1
      endif
      nueflag=0

! Check the message plus hash against what was sent.
      do i=1,K
        if( msgbits(i) .ne. decoded(i) ) then
          nueflag=1
        endif
      enddo
      if( nhashflag .eq. 1 .and. nueflag .eq. 0 ) then
        ngood=ngood+1
        nerrdec(nerr)=nerrdec(nerr)+1
      else if( nhashflag .eq. 1 .and. nueflag .eq. 1 ) then
        nue=nue+1;
      endif
    endif
  enddo
  snr2500=db-3.5
  write(*,"(f4.1,4x,f5.1,1x,i8,1x,i8,1x,i8,8x,f5.2)") db,snr2500,ngood,nue,nbadhash,ss

enddo

open(unit=23,file='nerrhisto.dat',status='unknown')
do i=1,128
  write(23,'(i4,2x,i10,i10,f10.2)') i,nerrdec(i),nerrtot(i),real(nerrdec(i))/real(nerrtot(i)+1e-10)
enddo
close(23)

end program ldpcsim
