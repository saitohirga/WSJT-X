program ldpcsim

use, intrinsic :: iso_c_binding
use hashing
use packjt

character*22 msg,msgsent,msgreceived
character*8 arg
integer*1, allocatable ::  codeword(:), decoded(:), message(:)
real*8, allocatable ::  rxdata(:), rxavgd(:)
real, allocatable :: llr(:)
integer ihash
integer*1 hardbits(32)

nargs=iargc()
if(nargs.ne.4) then
   print*,'Usage: ldpcsim  niter navg   #trials  s '
   print*,'eg:    ldpcsim   10     1     1000    0.75'
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

K=16
N=32
!rate=real(K)/real(N)
! don't count hash bits as data bits
rate=4.0/real(N)
write(*,*) "rate: ",rate
write(*,*) "niter= ",max_iterations,"navg= ",navg," s= ",s

allocate ( codeword(N), decoded(K), message(K) )
allocate ( rxdata(N), rxavgd(N), llr(N) )

msg="K1JT K9AN"
call fmtmsg(msg,iz)
call hash(msg,22,ihash)
irpt=14
ihash=iand(ihash,4095)                 !12-bit hash
ig=16*ihash + irpt                     !4-bit report
write(*,*) irpt,ihash,ig

do i=1,16
  message(i)=iand(1,ishft(ig,1-i))
enddo
write(*,'(16i1)') message
call encode_msk40(message,codeword)
write(*,'(32i1)') codeword
call init_random_seed()

write(*,*) "Eb/N0  SNR2500   ngood  nundetected nbadhash"
do idb = 0, 30
  db=idb/2.0
  sigma=1/sqrt( 2*rate*(10**(db/10.0)) )
  ngood=0
  nue=0
  nbadhash=0

  itsum=0
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

! Correct signal normalization is important for this decoder.
    rxav=sum(rxdata)/N
    rx2av=sum(rxdata*rxdata)/N
    rxsig=sqrt(rx2av-rxav*rxav)
    rxdata=rxdata/rxsig
    if( s .le. 0 ) then
      ss=sigma
    else 
      ss=s
    endif

    llr=2.0*rxdata/(ss*ss)

    call bpdecode40(llr, max_iterations, decoded, niterations)
! If the decoder finds a valid codeword, niterations will be .ge. 0.
    if( niterations .ge. 0 ) then
      nueflag=0
      nhashflag=0
      imsg=0
      do i=1,16
        imsg=ishft(imsg,1)+iand(1,decoded(17-i))
      enddo
      nrxrpt=iand(imsg,15)
      nrxhash=(imsg-nrxrpt)/16
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
        itsum=itsum+niterations
      else if( nhashflag .eq. 0 .and. nueflag .eq. 1 ) then
        nue=nue+1;
      endif
    else
      hardbits=0
      where(llr .gt. 0) hardbits=1
!      write(*,'(32i1)') hardbits 
!      write(*,'(32i1)') codeword 
      isum=0
      do i=1,32
        if( hardbits(i) .ne. codeword(i) ) isum=isum+1
      enddo
!      write(*,*) 'number of errors ',isum
    endif
  enddo
  avits=real(itsum)/real(ngood+0.1)
  snr2500=db-10.0
  write(*,"(f4.1,4x,f5.1,1x,i8,1x,i8,1x,i8,1x,f8.2,1x,f8.1)") db,snr2500,ngood,nue,nbadhash,ss,avits

enddo

end program ldpcsim
