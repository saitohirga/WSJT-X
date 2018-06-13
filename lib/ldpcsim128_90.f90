program ldpcsim

use, intrinsic :: iso_c_binding
use iso_c_binding, only: c_loc,c_size_t
use crc
use packjt
integer, parameter:: NRECENT=10, N=128, K=90, M=N-K
character*12 recent_calls(NRECENT)
character*22 msg,msgsent,msgreceived
character*96 tmpchar
character*8 arg
integer*1, allocatable ::  codeword(:), decoded(:), message(:)
integer*1, target:: i1Msg8BitBytes(12)
integer*1 apmask(N),cw(N)
integer*1 i1hash(4)
integer*1 msgbits(90)
integer*2 checksum
integer*4 i4Msg6BitWords(13)
integer ihash
integer nerrtot(0:N),nerrdec(0:N),nmpcbad(0:K)
logical checksumok
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

rate=real(K)/real(N)

write(*,*) "rate: ",rate

write(*,*) "niter= ",max_iterations," navg= ",navg," s= ",s

allocate ( codeword(N), decoded(K), message(K) )
allocate ( lratio(N), rxdata(N), rxavgd(N), yy(N), llr(N) )

!msg="K9AN K1JT EN50"
msg="G4WJS K1JT FN20"
  call packmsg(msg,i4Msg6BitWords,itype,.false.) !Pack into 12 6-bit bytes
  call unpackmsg(i4Msg6BitWords,msgsent,.false.,'      ') !Unpack to get msgsent
  write(*,*) "message sent ",msgsent

  tmpchar=' '
  write(tmpchar,'(12b6)') i4Msg6BitWords(1:12)
  tmpchar(73:77)="00000"   !i5bit

  read(tmpchar,'(10b8)') i1Msg8BitBytes(1:10)
  write(*,*) i1Msg8BitBytes

  i1Msg8BitBytes(10:12)=0 
  checksum = crc13 (c_loc (i1Msg8BitBytes), 12)
  write(*,'(i6,3x,b13)') checksum,checksum

  write(tmpchar(78:90),'(b13)') checksum
  read(tmpchar,'(90i1)') msgbits(1:90)

  write(*,*) 'msgbits'
  write(*,'(28i1,1x,28i1,1x,16i1,1x,5i1,1x,13i1)') msgbits

  call encode128_90(msgbits,codeword)

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

    rxav=sum(rxdata)/N
    rx2av=sum(rxdata*rxdata)/N
    rxsig=sqrt(rx2av-rxav*rxav)
    rxdata=rxdata/rxsig
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

    apmask=0
! max_iterations is max number of belief propagation iterations
    call bpdecode128_90(llr, apmask, max_iterations, decoded, cw, nharderrors, niterations)

! If the decoder finds a valid codeword, nharderrors will be .ge. 0.
    if( nharderrors .ge. 0 ) then
      call extractmessage128_90(decoded,msgreceived,ncrcflag)
write(*,*) 'crc check flag ',ncrcflag
      if( ncrcflag .ne. 1 ) then
        nbadcrc=nbadcrc+1
      endif

      nueflag=0
      nerrmpc=0
      do i=1,K
        if( msgbits(i) .ne. decoded(i) ) then
          nueflag=1
          nerrmpc=nerrmpc+1
        endif
      enddo
      nmpcbad(nerrmpc)=nmpcbad(nerrmpc)+1
      if( ncrcflag .eq. 1) then
        ngood=ngood+1
        nerrdec(nerr)=nerrdec(nerr)+1
      else if(nueflag .eq. 1 ) then
        nue=nue+1;
      endif
    endif
  enddo
  snr2500=db-3.5
  pberr=real(nerr)/real(ntrials*N)
  write(*,"(f4.1,4x,f5.1,1x,i8,1x,i8,1x,i8,8x,f5.2,8x,e10.3)") db,snr2500,ngood,nue,nbadcrc,ss,pberr
  
enddo

open(unit=23,file='nerrhisto.dat',status='unknown')
do i=1,N
  write(23,'(i4,2x,i10,i10,f10.2)') i,nerrdec(i),nerrtot(i),real(nerrdec(i))/real(nerrtot(i)+1e-10)
enddo
close(23)
open(unit=25,file='nmpcbad.dat',status='unknown')
do i=1,K
  write(25,'(i4,2x,i10)') i,nmpcbad(i)
enddo
close(25)

end program ldpcsim
