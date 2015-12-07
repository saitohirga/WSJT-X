subroutine extract(s3,nadd,nqd,ntrials,naggressive,ndepth,nexp_decode,   &
     ncount,nhist,decoded,ltext,nsf)

! Input:
!   s3       64-point spectra for each of 63 data symbols
!   nadd     number of spectra summed into s3
!   nqd      0/1 to indicate decode attempt at QSO frequency

! Output:
!   ncount   number of symbols requiring correction (-1 for no KV decode)
!   nhist    maximum number of identical symbol values
!   decoded  decoded message (if ncount >=0)
!   ltext    true if decoded message is free text
!   nsf    0=no decode; 1=BM decode; 2=KV decode

  use prog_args                       !shm_key, exe_dir, data_dir
  use packjt

  real s3(64,63)
  character decoded*22
  integer dat4(12)
  integer mrsym(63),mr2sym(63),mrprob(63),mr2prob(63)
  integer correct(63),tmp(63)
  integer param(0:7)
  integer indx(0:62)
  real*8 tt
  logical nokv,ltext
  common/chansyms65/correct
  data nokv/.false./,nsec1/0/
  save

  nbirdie=20
  npct=50
  afac1=1.1
  nsf=0
  nfail=0
  decoded='                      '
  call pctile(s3,4032,npct,base)
  s3=s3/base
! Get most reliable and second-most-reliable symbol values, and their
! probabilities
1 call demod64a(s3,nadd,afac1,mrsym,mrprob,mr2sym,mr2prob,ntest,nlow)

  call chkhist(mrsym,nhist,ipk)       !Test for birdies and QRM
  if(nhist.ge.nbirdie) then
     nfail=nfail+1
     call pctile(s3,4032,npct,base)
     s3(ipk,1:63)=base
     if(nfail.gt.30) then
        decoded='                      '
        ncount=-1
        go to 900
     endif
     go to 1
  endif

  call graycode65(mrsym,63,-1)        !Remove gray code 
  call interleave63(mrsym,-1)         !Remove interleaving
  call interleave63(mrprob,-1)

  call graycode65(mr2sym,63,-1)      !Remove gray code and interleaving
  call interleave63(mr2sym,-1)       !from second-most-reliable symbols
  call interleave63(mr2prob,-1)
  ntry=0

  nverbose=0
  call timer('ftrsd   ',0)
  call ftrsd2(mrsym,mrprob,mr2sym,mr2prob,ntrials,nverbose,correct,   &
       param,indx,tt,ntry)
  call timer('ftrsd   ',1)
  ncandidates=param(0)
  nhard=param(1)
  nsoft=param(2)
  nerased=param(3)

  if(nhard.lt.0 .and. ndepth.ge.5) then
     call timer('exp_deco',0)
     call exp_decode65(mrsym,mrprob,mr2sym,nexp_decode,nhard,nsoft,nbest,  &
          correct)
     if(nbest.gt.72+2*naggressive) then
        nhard=-1
     endif
     call timer('exp_deco',1)
  endif

  ndone=ndone+1
  ncount=-1
  decoded='                      '
  ltext=.false.
  if(nhard.ge.0) then
    !turn the corrected symbol array into channel symbols for subtraction
    !pass it back to jt65a via common block "chansyms65"
     do i=1,12
        dat4(i)=correct(13-i)
     enddo
     do i=1,63
       tmp(i)=correct(64-i)
     enddo
     correct(1:63)=tmp(1:63)
     call interleave63(correct,63,1)
     call graycode65(correct,63,1)
     call unpackmsg(dat4,decoded)     !Unpack the user message
!  open(43,file='stats.dat',access='append',status='unknown')
!  write(43,*) nhard,nsoft,nerased,ntry
!  close(43)
     ncount=0
     if(iand(dat4(10),8).ne.0) ltext=.true.
     nsf=1
  endif
900 continue

  return
end subroutine extract
